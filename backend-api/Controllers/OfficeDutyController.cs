// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\backend-api\Controllers\OfficeDutyController.cs
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
    [Route("api/v1/duty")]
    public class OfficeDutyController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public OfficeDutyController(ApplicationDbContext context)
        {
            _context = context;
        }

        public class StartDutyRequest
        {
            public string Destination { get; set; } = string.Empty;
            public string Reason { get; set; } = string.Empty;
        }

        public class CoordinateRequest
        {
            public Guid DutyLogId { get; set; }
            public double Latitude { get; set; }
            public double Longitude { get; set; }
        }

        public class BackgroundLocationRequest
        {
            public double Latitude { get; set; }
            public double Longitude { get; set; }
        }

        [HttpPost("location")]
        public async Task<IActionResult> LogBackgroundLocation([FromBody] BackgroundLocationRequest request)
        {
            var empIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (empIdClaim == null || !Guid.TryParse(empIdClaim.Value, out Guid empId))
            {
                return Unauthorized();
            }

            var activeLog = await _context.OfficeDutyLogs
                .FirstOrDefaultAsync(d => d.EmployeeId == empId && d.Status == "Active");

            if (activeLog == null)
            {
                return BadRequest(new { message = "No active outdoor duty session found." });
            }

            var indianTimeZone = TimeZoneInfo.FindSystemTimeZoneById("India Standard Time");
            var localTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, indianTimeZone);

            if (localTime.Hour < 9 || localTime.Hour >= 18)
            {
                return BadRequest(new { message = "GPS coordinates are not tracked outside office hours." });
            }

            var coord = new LocationCoordinate
            {
                DutyLogId = activeLog.Id,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Timestamp = DateTime.UtcNow
            };

            _context.LocationCoordinates.Add(coord);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Background coordinate logged successfully." });
        }

        [HttpPost("start")]
        public async Task<IActionResult> StartDuty([FromBody] StartDutyRequest request)
        {
            var empIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (empIdClaim == null || !Guid.TryParse(empIdClaim.Value, out Guid empId))
            {
                return Unauthorized();
            }

            // Check if already on active duty
            var active = await _context.OfficeDutyLogs
                .AnyAsync(d => d.EmployeeId == empId && d.Status == "Active");

            if (active)
            {
                return BadRequest(new { message = "You already have an active outdoor duty session." });
            }

            var empName = User.FindFirst("FirstName")?.Value + " " + User.FindFirst("LastName")?.Value;

            var log = new OfficeDutyLog
            {
                EmployeeId = empId,
                EmployeeName = empName ?? "Staff Employee",
                Destination = request.Destination,
                Reason = request.Reason,
                Status = "Active",
                StartTime = DateTime.UtcNow
            };

            _context.OfficeDutyLogs.Add(log);

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = log.EmployeeName,
                Action = "GPS Duty Start",
                Details = $"Started out-of-office duty. Destination: {request.Destination}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(log);
        }

        [HttpPost("stop")]
        public async Task<IActionResult> StopDuty()
        {
            var empIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (empIdClaim == null || !Guid.TryParse(empIdClaim.Value, out Guid empId))
            {
                return Unauthorized();
            }

            var log = await _context.OfficeDutyLogs
                .FirstOrDefaultAsync(d => d.EmployeeId == empId && d.Status == "Active");

            if (log == null)
            {
                return BadRequest(new { message = "No active duty session found to stop." });
            }

            log.Status = "Completed";
            log.StopTime = DateTime.UtcNow;

            // Audit
            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = log.EmployeeName,
                Action = "GPS Duty Stop",
                Details = $"Completed out-of-office duty for destination: {log.Destination}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);

            await _context.SaveChangesAsync();

            return Ok(log);
        }

        [HttpPost("log-coordinate")]
        public async Task<IActionResult> LogCoordinate([FromBody] CoordinateRequest request)
        {
            var log = await _context.OfficeDutyLogs.FindAsync(request.DutyLogId);
            if (log == null) return NotFound(new { message = "Active duty session log not found." });

            if (log.Status != "Active")
            {
                return BadRequest(new { message = "Duty session is no longer active." });
            }

            // Compliance Rule: Tracking ONLY during office hours (e.g. 09:00 to 18:00 Local Time)
            // Get local time in India (IST / UTC +5:30)
            var indianTimeZone = TimeZoneInfo.FindSystemTimeZoneById("India Standard Time");
            var localTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, indianTimeZone);

            var startHour = 9;
            var endHour = 18;

            if (localTime.Hour < startHour || localTime.Hour >= endHour)
            {
                return BadRequest(new { message = "GPS coordinates are not tracked outside corporate office hours." });
            }

            var coord = new LocationCoordinate
            {
                DutyLogId = request.DutyLogId,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Timestamp = DateTime.UtcNow
            };

            _context.LocationCoordinates.Add(coord);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Coordinate logged successfully." });
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("active")]
        public async Task<IActionResult> GetActiveDuties()
        {
            var activeDuties = await _context.OfficeDutyLogs
                .Include(d => d.Coordinates)
                .Where(d => d.Status == "Active")
                .ToListAsync();

            return Ok(activeDuties);
        }
    }
}
