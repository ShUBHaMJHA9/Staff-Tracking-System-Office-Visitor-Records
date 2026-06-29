using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using IodEnterpriseApi.Data;
using IodEnterpriseApi.Models;
using System;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Linq;

namespace IodEnterpriseApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/v1/gatepass")]
    public class GatePassController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public GatePassController(ApplicationDbContext context)
        {
            _context = context;
        }

        public class CreatePassRequest
        {
            public string Reason { get; set; } = string.Empty;
            public string LeaveTime { get; set; } = string.Empty;
        }

        [HttpPost("request")]
        public async Task<IActionResult> RequestPass([FromBody] CreatePassRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
            {
                return Unauthorized();
            }

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "User not found." });

            var pass = new GatePass
            {
                UserId = userId,
                Reason = request.Reason,
                LeaveTime = request.LeaveTime,
                RequestTime = DateTime.UtcNow,
                ApprovalStatus = "Pending",
                PassCode = "GP-" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper()
            };

            _context.GatePasses.Add(pass);

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = $"{user.FirstName} {user.LastName}",
                Action = "Gate Pass Request",
                Details = $"Requested early leave gate pass. Reason: {request.Reason}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(pass);
        }

        [HttpGet("my-passes")]
        public async Task<IActionResult> GetMyPasses()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
            {
                return Unauthorized();
            }

            var passes = await _context.GatePasses
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.RequestTime)
                .ToListAsync();

            return Ok(passes);
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("pending")]
        public async Task<IActionResult> GetPendingRequests()
        {
            var pending = await _context.GatePasses
                .Include(p => p.User)
                .Where(p => p.ApprovalStatus == "Pending")
                .OrderByDescending(p => p.RequestTime)
                .ToListAsync();

            return Ok(pending);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("approve/{id}")]
        public async Task<IActionResult> ApprovePass(Guid id, [FromQuery] bool approve)
        {
            var pass = await _context.GatePasses.Include(p => p.User).FirstOrDefaultAsync(p => p.Id == id);
            if (pass == null) return NotFound(new { message = "Gate Pass request not found." });

            if (pass.ApprovalStatus != "Pending")
            {
                return BadRequest(new { message = "Request has already been processed." });
            }

            var adminName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            pass.ApprovalStatus = approve ? "Approved" : "Rejected";
            pass.ApprovedBy = adminName ?? "Admin";
            pass.ApprovedTime = DateTime.UtcNow;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = adminName ?? "Admin",
                Action = approve ? "Gate Pass Approved" : "Gate Pass Rejected",
                Details = $"{(approve ? "Approved" : "Rejected")} Gate Pass for employee {pass.User?.FirstName} {pass.User?.LastName}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(new { message = $"Gate Pass request {(approve ? "approved" : "rejected")} successfully.", pass });
        }

        [Authorize(Roles = "Admin,SecurityGuard")]
        [HttpPost("scan/{passCode}")]
        public async Task<IActionResult> ScanGatePass(string passCode)
        {
            var pass = await _context.GatePasses.Include(p => p.User).FirstOrDefaultAsync(p => p.PassCode == passCode);
            if (pass == null) return NotFound(new { message = "Invalid Gate Pass code." });

            if (pass.ApprovalStatus != "Approved")
            {
                return BadRequest(new { message = $"Gate Pass is {pass.ApprovalStatus} (requires Approved)." });
            }

            if (pass.IsUsed)
            {
                return BadRequest(new { message = "Gate Pass has already been used." });
            }

            // Verify and clock out employee
            var activeLog = await _context.AttendanceLogs
                .FirstOrDefaultAsync(l => l.UserId == pass.UserId && l.CheckOut == null);

            var guardName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            if (activeLog != null)
            {
                activeLog.CheckOut = DateTime.UtcNow;
                activeLog.CheckedOutBy = "Gate Pass Scan (" + (guardName ?? "Security Guard") + ")";
            }

            pass.IsUsed = true;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = guardName ?? "Security Guard",
                Action = "Gate Pass Redeemed",
                Details = $"Scanned & redeemed early checkout gate pass for {pass.User?.FirstName} {pass.User?.LastName}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(new { message = "Gate Pass verified successfully. Employee clocked out.", employee = pass.User });
        }
    }
}
