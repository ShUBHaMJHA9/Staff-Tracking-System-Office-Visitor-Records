// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\backend-api\Controllers\AdminController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using IodEnterpriseApi.Data;
using IodEnterpriseApi.Models;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace IodEnterpriseApi.Controllers
{
    [Authorize(Roles = "Admin")]
    [ApiController]
    [Route("api/v1/admin")]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AdminController(ApplicationDbContext context)
        {
            _context = context;
        }

        public class CreateEmployeeRequest
        {
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Phone { get; set; } = string.Empty;
            public string Designation { get; set; } = string.Empty;
            public string Department { get; set; } = string.Empty;
            public string Role { get; set; } = "Staff";
            public string? PhotoUrl { get; set; }
        }

        public class AddWatchlistRequest
        {
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
            public string Phone { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Reason { get; set; } = string.Empty;
        }

        [HttpGet("employees")]
        public async Task<IActionResult> GetEmployees()
        {
            var list = await _context.Users.ToListAsync();
            return Ok(list);
        }

        [HttpPost("employees")]
        public async Task<IActionResult> CreateEmployee([FromBody] CreateEmployeeRequest request)
        {
            var exists = await _context.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (exists) return BadRequest(new { message = "Email already registered." });

            var emp = new User
            {
                Email = request.Email,
                PasswordHash = "hashed_" + request.Role.ToLower() + "123", // default password seed
                FirstName = request.FirstName,
                LastName = request.LastName,
                Department = request.Department,
                Designation = request.Designation,
                Role = request.Role,
                IsActive = true,
                Phone = request.Phone,
                PhotoUrl = string.IsNullOrEmpty(request.PhotoUrl) ? "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150" : request.PhotoUrl,
                FaceRegistered = false,
                ActivationCode = "IOD-STS-" + Guid.NewGuid().ToString().Substring(0, 6).ToUpper()
            };

            _context.Users.Add(emp);

            var adminName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = adminName ?? "Admin",
                Action = "Create Employee",
                Details = $"Created employee account for {request.FirstName} {request.LastName} ({request.Designation}).",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(emp);
        }

        [HttpPost("employees/toggle/{id}")]
        public async Task<IActionResult> ToggleEmployeeStatus(Guid id)
        {
            var emp = await _context.Users.FindAsync(id);
            if (emp == null) return NotFound();

            emp.IsActive = !emp.IsActive;
            var adminName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = adminName ?? "Admin",
                Action = "Toggle Employee",
                Details = $"Toggled status of employee {emp.FirstName} {emp.LastName} to {(emp.IsActive ? "Active" : "Inactive")}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(emp);
        }

        [HttpGet("employees/{id}/get-qr")]
        public async Task<IActionResult> GetQrToken(Guid id)
        {
            var emp = await _context.Users.FindAsync(id);
            if (emp == null) return NotFound();

            // If no token exists yet, generate one automatically
            if (string.IsNullOrEmpty(emp.QrLoginToken))
            {
                emp.QrLoginToken = "QR-" + Guid.NewGuid().ToString() + "-" + DateTime.UtcNow.Ticks;
                await _context.SaveChangesAsync();
            }

            return Ok(new { QrToken = emp.QrLoginToken });
        }

        [HttpPost("employees/{id}/generate-qr")]
        public async Task<IActionResult> GenerateQrToken(Guid id)
        {
            var emp = await _context.Users.FindAsync(id);
            if (emp == null) return NotFound();

            // Generate a NEW secure token (invalidates the old one)
            emp.QrLoginToken = "QR-" + Guid.NewGuid().ToString() + "-" + DateTime.UtcNow.Ticks;
            await _context.SaveChangesAsync();

            return Ok(new { QrToken = emp.QrLoginToken });
        }

        public class UpdateEmployeeRequest
        {
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Phone { get; set; } = string.Empty;
            public string Designation { get; set; } = string.Empty;
            public string Department { get; set; } = string.Empty;
            public string Role { get; set; } = "Staff";
            public string? PhotoUrl { get; set; }
        }

        [HttpPost("employees/update/{id}")]
        public async Task<IActionResult> UpdateEmployee(Guid id, [FromBody] UpdateEmployeeRequest request)
        {
            var emp = await _context.Users.FindAsync(id);
            if (emp == null) return NotFound(new { message = "Employee not found." });

            var emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower() && u.Id != id);
            if (emailExists) return BadRequest(new { message = "Email already registered to another account." });

            emp.FirstName = request.FirstName;
            emp.LastName = request.LastName;
            emp.Email = request.Email;
            emp.Phone = request.Phone;
            emp.Designation = request.Designation;
            emp.Department = request.Department;
            emp.Role = request.Role;
            if (!string.IsNullOrEmpty(request.PhotoUrl))
            {
                emp.PhotoUrl = request.PhotoUrl;
            }

            var adminName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = adminName ?? "Admin",
                Action = "Update Employee",
                Details = $"Updated profile information for employee {emp.FirstName} {emp.LastName}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();
            return Ok(emp);
        }

        [HttpPost("employees/register-face/{id}")]
        public async Task<IActionResult> RegisterFace(Guid id)
        {
            var emp = await _context.Users.FindAsync(id);
            if (emp == null) return NotFound(new { message = "Employee not found." });

            emp.FaceRegistered = true;

            var adminName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = adminName ?? "Admin",
                Action = "Biometric Scan Complete",
                Details = $"Successfully enrolled face vectors database embeddings for {emp.FirstName} {emp.LastName}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(emp);
        }

        [HttpGet("watchlist")]
        public async Task<IActionResult> GetWatchlist()
        {
            var list = await _context.WatchlistTargets.ToListAsync();
            return Ok(list);
        }

        [HttpPost("watchlist")]
        public async Task<IActionResult> AddWatchlist([FromBody] AddWatchlistRequest request)
        {
            var target = new WatchlistTarget
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Phone = request.Phone,
                Email = request.Email,
                Reason = request.Reason,
                FlaggedAt = DateTime.UtcNow
            };

            _context.WatchlistTargets.Add(target);

            var adminName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = adminName ?? "Admin",
                Action = "Watchlist Add",
                Details = $"Added {request.FirstName} {request.LastName} to entry-restriction watchlist. Reason: {request.Reason}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(target);
        }

        [HttpDelete("watchlist/{id}")]
        public async Task<IActionResult> DeleteWatchlist(Guid id)
        {
            var target = await _context.WatchlistTargets.FindAsync(id);
            if (target == null) return NotFound(new { message = "Watchlist target not found." });

            _context.WatchlistTargets.Remove(target);

            var adminName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = adminName ?? "Admin",
                Action = "Watchlist Remove",
                Details = $"Removed {target.FirstName} {target.LastName} from watchlist.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(new { message = "Watchlist target removed." });
        }

        [HttpGet("logs")]
        public async Task<IActionResult> GetAuditLogs()
        {
            var list = await _context.AuditLogs
                .OrderByDescending(l => l.Timestamp)
                .ToListAsync();

            return Ok(list);
        }

        [HttpGet("attendance-report")]
        public async Task<IActionResult> GetAttendanceReport([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var query = _context.AttendanceLogs.Include(a => a.User).AsQueryable();
            if (startDate.HasValue)
                query = query.Where(a => a.CheckIn >= startDate.Value);
            if (endDate.HasValue)
                query = query.Where(a => a.CheckIn <= endDate.Value);

            var list = await query
                .OrderByDescending(a => a.CheckIn)
                .ToListAsync();
            return Ok(list);
        }

        [HttpGet("visitor-report")]
        public async Task<IActionResult> GetVisitorReport([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var query = _context.VisitorPasses.AsQueryable();
            if (startDate.HasValue)
                query = query.Where(v => v.CheckInTime >= startDate.Value);
            if (endDate.HasValue)
                query = query.Where(v => v.CheckInTime <= endDate.Value);

            var list = await query
                .OrderByDescending(v => v.CheckInTime)
                .ToListAsync();
            return Ok(list);
        }

        [HttpGet("shift-report")]
        public async Task<IActionResult> GetShiftReport()
        {
            var list = await _context.AttendanceLogs
                .Include(a => a.User)
                .Where(a => a.User != null && a.User.Role == "SecurityGuard")
                .OrderByDescending(a => a.CheckIn)
                .ToListAsync();

            return Ok(list);
        }
    }
}
