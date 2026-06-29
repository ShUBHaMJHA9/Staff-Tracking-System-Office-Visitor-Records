// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\backend-api\Controllers\VisitorController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using IodEnterpriseApi.Data;
using IodEnterpriseApi.Models;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

namespace IodEnterpriseApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/v1/visitor")]
    public class VisitorController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public VisitorController(ApplicationDbContext context)
        {
            _context = context;
        }

        public class PreRegisterRequest
        {
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Phone { get; set; } = string.Empty;
            public string Company { get; set; } = string.Empty;
            public string Purpose { get; set; } = string.Empty;
        }

        public class CheckInRequest
        {
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Phone { get; set; } = string.Empty;
            public string Company { get; set; } = string.Empty;
            public string Designation { get; set; } = string.Empty;
            public string VisitorCardId { get; set; } = string.Empty;
            public string PhotoUrl { get; set; } = string.Empty;
            public Guid HostEmployeeId { get; set; }
            public string Purpose { get; set; } = string.Empty;
            public bool CardScanned { get; set; } = false;
        }

        [HttpPost("pre-register")]
        public async Task<IActionResult> PreRegister([FromBody] PreRegisterRequest request)
        {
            var hostIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (hostIdClaim == null || !Guid.TryParse(hostIdClaim.Value, out Guid hostId))
            {
                return Unauthorized();
            }

            var host = await _context.Users.FindAsync(hostId);
            if (host == null) return NotFound(new { message = "Host employee not found." });

            var pass = new VisitorPass
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Phone = request.Phone,
                Company = request.Company,
                HostEmployeeId = hostId,
                HostName = $"{host.FirstName} {host.LastName}",
                HostDepartment = host.Department,
                Purpose = request.Purpose,
                Status = "Pre-registered"
            };

            _context.VisitorPasses.Add(pass);

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = $"{host.FirstName} {host.LastName}",
                Action = "Pre-register Visitor",
                Details = $"Pre-registered guest {request.FirstName} {request.LastName} from {request.Company}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetActiveVisitors), new { id = pass.Id }, pass);
        }

        [HttpGet("lookup/{cardId}")]
        public async Task<IActionResult> LookupVisitor(string cardId)
        {
            if (string.IsNullOrEmpty(cardId)) return BadRequest(new { message = "Invalid card ID." });

            var match = await _context.VisitorPasses
                .Where(v => v.VisitorCardId == cardId)
                .OrderByDescending(v => v.CheckInTime)
                .FirstOrDefaultAsync();

            if (match == null) return NotFound(new { message = "No visitor registered with this card yet." });

            return Ok(match);
        }

        [HttpGet("employees")]
        public async Task<IActionResult> GetEmployeesForDropdown()
        {
            var list = await _context.Users
                .Where(u => u.Role == "Staff" || u.Role == "Admin")
                .Select(u => new
                {
                    id = u.Id,
                    firstName = u.FirstName,
                    lastName = u.LastName,
                    designation = u.Designation,
                    department = u.Department,
                    role = u.Role
                })
                .ToListAsync();
            return Ok(list);
        }

        [HttpPost("check-in")]
        public async Task<IActionResult> CheckIn([FromBody] CheckInRequest request)
        {
            // Verify roles: Only Admin or Guard can check in visitors directly
            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            if (userRole != "Admin" && userRole != "SecurityGuard")
            {
                return Forbid();
            }

            var host = await _context.Users.FindAsync(request.HostEmployeeId);
            if (host == null) return BadRequest(new { message = "Selected host employee not found." });

            // Watchlist verification (Check by email or phone)
            var blacklisted = await _context.WatchlistTargets
                .AnyAsync(w => w.Email.ToLower() == request.Email.ToLower() || w.Phone == request.Phone);

            var pass = new VisitorPass
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Phone = request.Phone,
                Company = request.Company,
                Designation = request.Designation,
                VisitorCardId = request.VisitorCardId,
                HostEmployeeId = request.HostEmployeeId,
                HostName = $"{host.FirstName} {host.LastName}",
                HostDepartment = host.Department,
                Purpose = request.Purpose,
                Status = "Checked In",
                CheckInTime = DateTime.UtcNow,
                CardScanned = request.CardScanned,
                PhotoUrl = string.IsNullOrEmpty(request.PhotoUrl) 
                    ? "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150" 
                    : request.PhotoUrl
            };

            _context.VisitorPasses.Add(pass);

            // Audit & Watchlist Warning Logs
            var guardName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;
            if (blacklisted)
            {
                var warningLog = new AuditLog
                {
                    Timestamp = DateTime.UtcNow,
                    User = "Security Shield",
                    Action = "Watchlist Triggered",
                    Details = $"SECURITY ALERT: Blacklisted visitor {request.FirstName} {request.LastName} attempted entry! Silent alert dispatched.",
                    Severity = "warning"
                };
                _context.AuditLogs.Add(warningLog);
            }

            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = guardName ?? "Security Guard",
                Action = "Visitor Check-In",
                Details = $"Checked in visitor {request.FirstName} {request.LastName} for host {pass.HostName}." + 
                          (request.CardScanned ? " (OCR Card Scanned)" : " (Manual Entry)"),
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Pass = pass,
                WatchlistTriggered = blacklisted,
                Message = blacklisted 
                    ? "Warning: Visitor flagged on security watchlist. Silent alerts sent to supervisors."
                    : "Visitor checked in successfully."
            });
        }

        [HttpPost("check-out/{id}")]
        public async Task<IActionResult> CheckOut(Guid id)
        {
            var pass = await _context.VisitorPasses.FindAsync(id);
            if (pass == null) return NotFound(new { message = "Visitor record not found." });

            if (pass.Status != "Checked In")
            {
                return BadRequest(new { message = "Visitor is not checked in." });
            }

            pass.Status = "Checked Out";
            pass.CheckOutTime = DateTime.UtcNow;

            var actorName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = actorName ?? "System",
                Action = "Visitor Check-Out",
                Details = $"Checked out visitor {pass.FirstName} {pass.LastName}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Visitor checked out successfully.",
                CheckOutTime = pass.CheckOutTime
            });
        }

        [HttpGet("active")]
        public async Task<IActionResult> GetActiveVisitors()
        {
            var active = await _context.VisitorPasses
                .Where(v => v.Status == "Checked In")
                .ToListAsync();

            return Ok(active);
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("all")]
        public async Task<IActionResult> GetAllVisitors()
        {
            var all = await _context.VisitorPasses
                .OrderByDescending(v => v.CheckInTime)
                .ToListAsync();

            return Ok(all);
        }
    }
}
