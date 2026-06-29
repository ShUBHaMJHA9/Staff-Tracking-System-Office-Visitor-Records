// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\backend-api\Data\ApplicationDbContext.cs
using Microsoft.EntityFrameworkCore;
using IodEnterpriseApi.Models;
using System;

namespace IodEnterpriseApi.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; } = null!;
        public DbSet<AttendanceLog> AttendanceLogs { get; set; } = null!;
        public DbSet<VisitorPass> VisitorPasses { get; set; } = null!;
        public DbSet<OfficeDutyLog> OfficeDutyLogs { get; set; } = null!;
        public DbSet<LocationCoordinate> LocationCoordinates { get; set; } = null!;
        public DbSet<WatchlistTarget> WatchlistTargets { get; set; } = null!;
        public DbSet<AuditLog> AuditLogs { get; set; } = null!;
        public DbSet<GatePass> GatePasses { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Relationships
            modelBuilder.Entity<OfficeDutyLog>()
                .HasMany(d => d.Coordinates)
                .WithOne(c => c.DutyLog)
                .HasForeignKey(c => c.DutyLogId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<LocationCoordinate>()
                .Property(e => e.Latitude)
                .HasConversion(
                    v => IodEnterpriseApi.Services.EncryptionService.EncryptDouble(v),
                    v => IodEnterpriseApi.Services.EncryptionService.DecryptDouble(v)
                )
                .HasColumnType("TEXT");

            modelBuilder.Entity<LocationCoordinate>()
                .Property(e => e.Longitude)
                .HasConversion(
                    v => IodEnterpriseApi.Services.EncryptionService.EncryptDouble(v),
                    v => IodEnterpriseApi.Services.EncryptionService.DecryptDouble(v)
                )
                .HasColumnType("TEXT");

            // Seed Initial Data (Matches React MockDatabase)
            var adminId = Guid.Parse("00000000-0000-0000-0000-000000000001");
            var staffId = Guid.Parse("00000000-0000-0000-0000-000000000002");
            var hrId = Guid.Parse("00000000-0000-0000-0000-000000000003");
            var guardId = Guid.Parse("00000000-0000-0000-0000-000000000004");

            // Mock Password Hashes (Using a constant representing hashed value of "admin123", "staff123", "guard123")
            // In a real production setup, these would be generated dynamically using BCrypt.Net.
            const string mockHashAdmin = "hashed_admin123";
            const string mockHashStaff = "hashed_staff123";
            const string mockHashGuard = "hashed_guard123";

            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = adminId,
                    Email = "admin@iod.com",
                    PasswordHash = mockHashAdmin,
                    FirstName = "Ravi Shankar",
                    LastName = "Swami",
                    Department = "Web & IT",
                    Designation = "General Manager",
                    Role = "Admin",
                    IsActive = true,
                    Phone = "+91-9988776655",
                    PhotoUrl = "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150",
                    FaceRegistered = true
                },
                new User
                {
                    Id = staffId,
                    Email = "shubham@iod.com",
                    PasswordHash = mockHashStaff,
                    FirstName = "Shubham",
                    LastName = "Kumar",
                    Department = "Web & IT",
                    Designation = "Software Engineering Intern",
                    Role = "Staff",
                    IsActive = true,
                    Phone = "+91-9876543210",
                    PhotoUrl = "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
                    FaceRegistered = true
                },
                new User
                {
                    Id = hrId,
                    Email = "anita.hr@iod.com",
                    PasswordHash = mockHashStaff,
                    FirstName = "Anita",
                    LastName = "Sharma",
                    Department = "Human Resources",
                    Designation = "HR Lead",
                    Role = "Staff",
                    IsActive = true,
                    Phone = "+91-8888777766",
                    PhotoUrl = "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150",
                    FaceRegistered = false
                },
                new User
                {
                    Id = guardId,
                    Email = "guard@iod.com",
                    PasswordHash = mockHashGuard,
                    FirstName = "Satish",
                    LastName = "Singh",
                    Department = "Security Operations",
                    Designation = "Lobby Security Supervisor",
                    Role = "SecurityGuard",
                    IsActive = true,
                    Phone = "+91-7777666655",
                    PhotoUrl = "https://images.unsplash.com/photo-1621574539437-4b7cb63120b8?w=150",
                    FaceRegistered = true
                },
                new User
                {
                    Id = Guid.Parse("00000000-0000-0000-0000-000000000005"),
                    Email = "exec@iod.com",
                    PasswordHash = mockHashStaff,
                    FirstName = "Arun",
                    LastName = "Bajaj",
                    Department = "Corporate Affairs",
                    Designation = "Executive Director",
                    Role = "Staff",
                    IsActive = true,
                    Phone = "+91-9999888877",
                    PhotoUrl = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                    FaceRegistered = true
                },
                new User
                {
                    Id = Guid.Parse("00000000-0000-0000-0000-000000000006"),
                    Email = "analyst@iod.com",
                    PasswordHash = mockHashStaff,
                    FirstName = "Priya",
                    LastName = "Menon",
                    Department = "Finance & Accounting",
                    Designation = "Senior Analyst",
                    Role = "Staff",
                    IsActive = true,
                    Phone = "+91-8888999900",
                    PhotoUrl = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
                    FaceRegistered = true
                },
                new User
                {
                    Id = Guid.Parse("00000000-0000-0000-0000-000000000007"),
                    Email = "itadmin@iod.com",
                    PasswordHash = mockHashStaff,
                    FirstName = "Karthik",
                    LastName = "Raman",
                    Department = "Web & IT",
                    Designation = "IT Administrator",
                    Role = "Staff",
                    IsActive = true,
                    Phone = "+91-7777888899",
                    PhotoUrl = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
                    FaceRegistered = false
                },
                new User
                {
                    Id = Guid.Parse("00000000-0000-0000-0000-000000000008"),
                    Email = "secretary@iod.com",
                    PasswordHash = mockHashStaff,
                    FirstName = "Sneha",
                    LastName = "Rao",
                    Department = "Corporate Affairs",
                    Designation = "Board Secretary",
                    Role = "Staff",
                    IsActive = true,
                    Phone = "+91-6666777788",
                    PhotoUrl = "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150",
                    FaceRegistered = true
                },
                new User
                {
                    Id = Guid.Parse("00000000-0000-0000-0000-000000000009"),
                    Email = "security@iod.com",
                    PasswordHash = mockHashGuard,
                    FirstName = "Vikram",
                    LastName = "Singh",
                    Department = "Security Operations",
                    Designation = "Security Specialist",
                    Role = "SecurityGuard",
                    IsActive = true,
                    Phone = "+91-5555666677",
                    PhotoUrl = "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150",
                    FaceRegistered = false
                }
            );

            modelBuilder.Entity<WatchlistTarget>().HasData(
                new WatchlistTarget
                {
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    FirstName = "Suresh",
                    LastName = "Mehta",
                    Phone = "+91-9000111222",
                    Email = "suresh@blacklisted.com",
                    Reason = "Disruptive behavior during General Meeting",
                    FlaggedAt = new DateTime(2026, 05, 10, 11, 0, 0, DateTimeKind.Utc)
                }
            );

            modelBuilder.Entity<AuditLog>().HasData(
                new AuditLog
                {
                    Id = Guid.Parse("22222222-2222-2222-2222-222222222221"),
                    Timestamp = new DateTime(2026, 6, 26, 12, 0, 0, DateTimeKind.Utc),
                    User = "Satish Singh (Guard)",
                    Action = "Visitor Check-in",
                    Details = "Checked in Rajesh Kumar from ABC Solutions Ltd. Card scanned successfully.",
                    Severity = "info"
                },
                new AuditLog
                {
                    Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    Timestamp = new DateTime(2026, 6, 26, 11, 50, 0, DateTimeKind.Utc),
                    User = "System",
                    Action = "GPS Office Duty Start",
                    Details = "Employee Shubham Kumar initiated out-of-office GPS Duty Tracking (Destination: Nehru Place).",
                    Severity = "info"
                }
            );

            // Seed active office duties for Live Field Tracking
            var duty1Id = Guid.Parse("33333333-3333-3333-3333-333333333331");
            var duty2Id = Guid.Parse("33333333-3333-3333-3333-333333333332");

            modelBuilder.Entity<OfficeDutyLog>().HasData(
                new OfficeDutyLog
                {
                    Id = duty1Id,
                    EmployeeId = staffId,
                    EmployeeName = "Shubham Kumar",
                    Destination = "Nehru Place Client Center",
                    Reason = "Hardware installation & website training for Directors",
                    Status = "Active",
                    StartTime = new DateTime(2026, 6, 26, 11, 0, 0, DateTimeKind.Utc)
                },
                new OfficeDutyLog
                {
                    Id = duty2Id,
                    EmployeeId = hrId,
                    EmployeeName = "Anita Sharma",
                    Destination = "Connaught Place Head Office",
                    Reason = "Quarterly HR compliance audit",
                    Status = "Active",
                    StartTime = new DateTime(2026, 6, 26, 11, 30, 0, DateTimeKind.Utc)
                }
            );

            modelBuilder.Entity<LocationCoordinate>().HasData(
                new LocationCoordinate { Id = Guid.Parse("44444444-4444-4444-4444-444444444441"), DutyLogId = duty1Id, Latitude = 28.5494, Longitude = 77.2519, Timestamp = new DateTime(2026, 6, 26, 11, 10, 0, DateTimeKind.Utc) },
                new LocationCoordinate { Id = Guid.Parse("44444444-4444-4444-4444-444444444442"), DutyLogId = duty1Id, Latitude = 28.5480, Longitude = 77.2525, Timestamp = new DateTime(2026, 6, 26, 11, 20, 0, DateTimeKind.Utc) },
                new LocationCoordinate { Id = Guid.Parse("44444444-4444-4444-4444-444444444443"), DutyLogId = duty1Id, Latitude = 28.5471, Longitude = 77.2536, Timestamp = new DateTime(2026, 6, 26, 11, 40, 0, DateTimeKind.Utc) },
                new LocationCoordinate { Id = Guid.Parse("44444444-4444-4444-4444-444444444444"), DutyLogId = duty1Id, Latitude = 28.5460, Longitude = 77.2550, Timestamp = new DateTime(2026, 6, 26, 11, 55, 0, DateTimeKind.Utc) },
                
                new LocationCoordinate { Id = Guid.Parse("44444444-4444-4444-4444-444444444445"), DutyLogId = duty2Id, Latitude = 28.6280, Longitude = 77.2155, Timestamp = new DateTime(2026, 6, 26, 11, 35, 0, DateTimeKind.Utc) },
                new LocationCoordinate { Id = Guid.Parse("44444444-4444-4444-4444-444444444446"), DutyLogId = duty2Id, Latitude = 28.6304, Longitude = 77.2177, Timestamp = new DateTime(2026, 6, 26, 11, 50, 0, DateTimeKind.Utc) }
            );
        }
    }
}
