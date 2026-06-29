// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\backend-api\Models\Entities.cs
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace IodEnterpriseApi.Models
{
    public class User
    {
        [Key]
        public Guid Id { get; set; }

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [JsonIgnore] // Never send password hash in JSON responses
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        public string LastName { get; set; } = string.Empty;

        [Required]
        public string Department { get; set; } = string.Empty;

        [Required]
        public string Designation { get; set; } = string.Empty;

        [Required]
        public string Role { get; set; } = "Staff"; // Admin, SecurityGuard, Staff

        public bool IsActive { get; set; } = true;

        public string Phone { get; set; } = string.Empty;

        public string PhotoUrl { get; set; } = string.Empty;

        public bool FaceRegistered { get; set; } = false;

        // --- Omni-Auth & Single Device Fields ---
        public Guid? ActiveTokenId { get; set; }
        
        public string? ActivationCode { get; set; }
        public string? CurrentOtp { get; set; }
        public DateTime? OtpExpiry { get; set; }
        public string? QrLoginToken { get; set; }
        
        public bool IsDeviceRegistered { get; set; } = false;
        public string? RegisteredDeviceId { get; set; }
    }

    public class AttendanceLog
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        [Required]
        public DateTime CheckIn { get; set; }

        public DateTime? CheckOut { get; set; }

        [Required]
        public string CheckInMethod { get; set; } = "Web"; // Face, QR, Web

        public string IPAddress { get; set; } = string.Empty;

        public string CheckedInBy { get; set; } = "Self";

        public string CheckedOutBy { get; set; } = string.Empty;
    }

    public class VisitorPass
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        public string LastName { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Phone { get; set; } = string.Empty;

        [Required]
        public string Company { get; set; } = string.Empty;

        public string Designation { get; set; } = string.Empty;

        public string VisitorCardId { get; set; } = string.Empty;

        [Required]
        public Guid HostEmployeeId { get; set; }

        [Required]
        public string HostName { get; set; } = string.Empty;

        [Required]
        public string HostDepartment { get; set; } = string.Empty;

        [Required]
        public string Purpose { get; set; } = string.Empty;

        [Required]
        public string Status { get; set; } = "Pre-registered"; // Pre-registered, Checked In, Checked Out

        public DateTime? CheckInTime { get; set; }

        public DateTime? CheckOutTime { get; set; }

        public bool CardScanned { get; set; } = false;

        public string PhotoUrl { get; set; } = string.Empty;
    }

    public class OfficeDutyLog
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid EmployeeId { get; set; }

        [Required]
        public string EmployeeName { get; set; } = string.Empty;

        [Required]
        public string Destination { get; set; } = string.Empty;

        [Required]
        public string Reason { get; set; } = string.Empty;

        [Required]
        public string Status { get; set; } = "Active"; // Active, Completed

        [Required]
        public DateTime StartTime { get; set; }

        public DateTime? StopTime { get; set; }

        public List<LocationCoordinate> Coordinates { get; set; } = new();
    }

    public class LocationCoordinate
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid DutyLogId { get; set; }

        [ForeignKey("DutyLogId")]
        [JsonIgnore]
        public OfficeDutyLog? DutyLog { get; set; }

        [Required]
        public double Latitude { get; set; }

        [Required]
        public double Longitude { get; set; }

        [Required]
        public DateTime Timestamp { get; set; }
    }

    public class WatchlistTarget
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        public string LastName { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        [Required]
        public string Reason { get; set; } = string.Empty;

        [Required]
        public DateTime FlaggedAt { get; set; }
    }

    public class GatePass
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        [Required]
        public string Reason { get; set; } = string.Empty;

        public string LeaveTime { get; set; } = string.Empty;

        [Required]
        public DateTime RequestTime { get; set; }

        [Required]
        public string ApprovalStatus { get; set; } = "Pending"; // Pending, Approved, Rejected

        public string ApprovedBy { get; set; } = string.Empty;

        public DateTime? ApprovedTime { get; set; }

        [Required]
        public string PassCode { get; set; } = string.Empty;

        public bool IsUsed { get; set; } = false;
    }

    public class AuditLog
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public DateTime Timestamp { get; set; }

        [Required]
        public string User { get; set; } = string.Empty;

        [Required]
        public string Action { get; set; } = string.Empty;

        [Required]
        public string Details { get; set; } = string.Empty;

        [Required]
        public string Severity { get; set; } = "info"; // info, warning, error
    }
}
