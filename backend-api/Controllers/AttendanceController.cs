// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\backend-api\Controllers\AttendanceController.cs
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
    [Route("api/v1/attendance")]
    public class AttendanceController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AttendanceController(ApplicationDbContext context)
        {
            _context = context;
        }

        public class CheckInRequest
        {
            public string Method { get; set; } = "Web"; // Face, QR, Web
            public string IPAddress { get; set; } = string.Empty;
        }

        [HttpPost("check-in")]
        public async Task<IActionResult> CheckIn([FromBody] CheckInRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
            {
                return Unauthorized(new { message = "Invalid token credentials." });
            }

            // Check if already checked in today (active log without checkout)
            var activeLog = await _context.AttendanceLogs
                .FirstOrDefaultAsync(l => l.UserId == userId && l.CheckOut == null);

            if (activeLog != null)
            {
                return BadRequest(new { message = "You are already clocked in." });
            }

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "Employee not found." });

            // If checking in by Face, verify face registration is complete
            if (request.Method == "Face" && !user.FaceRegistered)
            {
                return BadRequest(new { message = "Biometric face registration must be enrolled first." });
            }

            var log = new AttendanceLog
            {
                UserId = userId,
                CheckIn = DateTime.UtcNow,
                CheckInMethod = request.Method,
                IPAddress = request.IPAddress,
                CheckedInBy = "Self (" + request.Method + ")"
            };

            _context.AttendanceLogs.Add(log);

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = $"{user.FirstName} {user.LastName}",
                Action = "Clock In",
                Details = $"Clocked in successfully using {request.Method}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Clocked in successfully.",
                LogId = log.Id,
                CheckIn = log.CheckIn,
                Method = log.CheckInMethod
            });
        }

        [HttpPost("check-out")]
        public async Task<IActionResult> CheckOut()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
            {
                return Unauthorized(new { message = "Invalid token credentials." });
            }

            var activeLog = await _context.AttendanceLogs
                .FirstOrDefaultAsync(l => l.UserId == userId && l.CheckOut == null);

            if (activeLog == null)
            {
                return BadRequest(new { message = "No active check-in found to clock out." });
            }

            activeLog.CheckOut = DateTime.UtcNow;
            activeLog.CheckedOutBy = "Self";

            var user = await _context.Users.FindAsync(userId);
            var name = user != null ? $"{user.FirstName} {user.LastName}" : "Employee";

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = name,
                Action = "Clock Out",
                Details = "Clocked out successfully.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Clocked out successfully.",
                LogId = activeLog.Id,
                CheckIn = activeLog.CheckIn,
                CheckOut = activeLog.CheckOut
            });
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
            {
                return Unauthorized();
            }

            var history = await _context.AttendanceLogs
                .Where(l => l.UserId == userId)
                .OrderByDescending(l => l.CheckIn)
                .Select(l => new
                {
                    id = l.Id,
                    checkIn = l.CheckIn,
                    checkOut = l.CheckOut,
                    checkInMethod = l.CheckInMethod,
                    checkedInBy = l.CheckedInBy,
                    checkedOutBy = l.CheckedOutBy
                })
                .ToListAsync();

            return Ok(history);
        }

        // Fast endpoint: returns the guard's current active shift (if any)
        [HttpGet("active-shift")]
        public async Task<IActionResult> GetActiveShift()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
            {
                return Unauthorized();
            }

            var activeLog = await _context.AttendanceLogs
                .Where(l => l.UserId == userId && l.CheckOut == null)
                .OrderByDescending(l => l.CheckIn)
                .FirstOrDefaultAsync();

            if (activeLog == null)
            {
                return Ok(new { isActive = false, logId = (string?)null, checkIn = (DateTime?)null });
            }

            return Ok(new
            {
                isActive = true,
                logId = activeLog.Id,
                checkIn = activeLog.CheckIn
            });
        }


        public class GuardCheckInRequest
        {
            public Guid UserId { get; set; }
            public string Method { get; set; } = "QR"; // QR, Face
            public string Direction { get; set; } = "In"; // In, Out
        }

        [Authorize(Roles = "Admin,SecurityGuard")]
        [HttpPost("register")]
        public async Task<IActionResult> RegisterAttendance([FromBody] GuardCheckInRequest request)
        {
            var user = await _context.Users.FindAsync(request.UserId);
            if (user == null) return NotFound(new { message = "Employee not found." });

            var guardName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;
            var guardActor = string.IsNullOrEmpty(guardName?.Trim()) ? "Security Guard" : guardName;

            if (request.Direction.Equals("In", StringComparison.OrdinalIgnoreCase))
            {
                // Check if already checked in
                var activeLog = await _context.AttendanceLogs
                    .FirstOrDefaultAsync(l => l.UserId == request.UserId && l.CheckOut == null);

                if (activeLog != null)
                {
                    return BadRequest(new { message = "Employee is already clocked in." });
                }

                 var log = new AttendanceLog
                {
                    UserId = request.UserId,
                    CheckIn = DateTime.UtcNow,
                    CheckInMethod = request.Method,
                    IPAddress = "Gate Guard Terminal",
                    CheckedInBy = guardActor
                };
                _context.AttendanceLogs.Add(log);

                // Audit
                var audit = new AuditLog
                {
                    Timestamp = DateTime.UtcNow,
                    User = guardActor,
                    Action = "Guard Clock In",
                    Details = $"Guard clocked in employee {user.FirstName} {user.LastName} via {request.Method}.",
                    Severity = "info"
                };
                _context.AuditLogs.Add(audit);
            }
            else
            {
                // Clock out
                var activeLog = await _context.AttendanceLogs
                    .FirstOrDefaultAsync(l => l.UserId == request.UserId && l.CheckOut == null);

                if (activeLog == null)
                {
                    return BadRequest(new { message = "No active check-in found for this employee." });
                }

                activeLog.CheckOut = DateTime.UtcNow;
                activeLog.CheckedOutBy = guardActor;

                // Audit
                var audit = new AuditLog
                {
                    Timestamp = DateTime.UtcNow,
                    User = guardActor,
                    Action = "Guard Clock Out",
                    Details = $"Guard clocked out employee {user.FirstName} {user.LastName}.",
                    Severity = "info"
                };
                _context.AuditLogs.Add(audit);
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = $"Employee attendance '{request.Direction}' registered successfully." });
        }

        [Authorize(Roles = "Admin,SecurityGuard")]
        [HttpGet("employee/{id}")]
        public async Task<IActionResult> GetEmployeeAttendanceState(Guid id)
        {
            var emp = await _context.Users.FindAsync(id);
            if (emp == null) return NotFound(new { message = "Employee not found." });

            var activeLog = await _context.AttendanceLogs
                .FirstOrDefaultAsync(l => l.UserId == id && l.CheckOut == null);

            return Ok(new
            {
                Employee = emp,
                IsClockedIn = activeLog != null,
                CheckInTime = activeLog?.CheckIn
            });
        }
    }
}
