using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace IodEnterpriseApi.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AuditLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "TEXT", nullable: false),
                    User = table.Column<string>(type: "TEXT", nullable: false),
                    Action = table.Column<string>(type: "TEXT", nullable: false),
                    Details = table.Column<string>(type: "TEXT", nullable: false),
                    Severity = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OfficeDutyLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    EmployeeId = table.Column<Guid>(type: "TEXT", nullable: false),
                    EmployeeName = table.Column<string>(type: "TEXT", nullable: false),
                    Destination = table.Column<string>(type: "TEXT", nullable: false),
                    Reason = table.Column<string>(type: "TEXT", nullable: false),
                    Status = table.Column<string>(type: "TEXT", nullable: false),
                    StartTime = table.Column<DateTime>(type: "TEXT", nullable: false),
                    StopTime = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OfficeDutyLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    Email = table.Column<string>(type: "TEXT", nullable: false),
                    PasswordHash = table.Column<string>(type: "TEXT", nullable: false),
                    FirstName = table.Column<string>(type: "TEXT", nullable: false),
                    LastName = table.Column<string>(type: "TEXT", nullable: false),
                    Department = table.Column<string>(type: "TEXT", nullable: false),
                    Designation = table.Column<string>(type: "TEXT", nullable: false),
                    Role = table.Column<string>(type: "TEXT", nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    Phone = table.Column<string>(type: "TEXT", nullable: false),
                    PhotoUrl = table.Column<string>(type: "TEXT", nullable: false),
                    FaceRegistered = table.Column<bool>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "VisitorPasses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    FirstName = table.Column<string>(type: "TEXT", nullable: false),
                    LastName = table.Column<string>(type: "TEXT", nullable: false),
                    Email = table.Column<string>(type: "TEXT", nullable: false),
                    Phone = table.Column<string>(type: "TEXT", nullable: false),
                    Company = table.Column<string>(type: "TEXT", nullable: false),
                    HostEmployeeId = table.Column<Guid>(type: "TEXT", nullable: false),
                    HostName = table.Column<string>(type: "TEXT", nullable: false),
                    HostDepartment = table.Column<string>(type: "TEXT", nullable: false),
                    Purpose = table.Column<string>(type: "TEXT", nullable: false),
                    Status = table.Column<string>(type: "TEXT", nullable: false),
                    CheckInTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CheckOutTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CardScanned = table.Column<bool>(type: "INTEGER", nullable: false),
                    PhotoUrl = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VisitorPasses", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WatchlistTargets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    FirstName = table.Column<string>(type: "TEXT", nullable: false),
                    LastName = table.Column<string>(type: "TEXT", nullable: false),
                    Phone = table.Column<string>(type: "TEXT", nullable: false),
                    Email = table.Column<string>(type: "TEXT", nullable: false),
                    Reason = table.Column<string>(type: "TEXT", nullable: false),
                    FlaggedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WatchlistTargets", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "LocationCoordinates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    DutyLogId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Latitude = table.Column<string>(type: "TEXT", nullable: false),
                    Longitude = table.Column<string>(type: "TEXT", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LocationCoordinates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LocationCoordinates_OfficeDutyLogs_DutyLogId",
                        column: x => x.DutyLogId,
                        principalTable: "OfficeDutyLogs",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AttendanceLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    UserId = table.Column<Guid>(type: "TEXT", nullable: false),
                    CheckIn = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CheckOut = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CheckInMethod = table.Column<string>(type: "TEXT", nullable: false),
                    IPAddress = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttendanceLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AttendanceLogs_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "AuditLogs",
                columns: new[] { "Id", "Action", "Details", "Severity", "Timestamp", "User" },
                values: new object[,]
                {
                    { new Guid("22222222-2222-2222-2222-222222222221"), "Visitor Check-in", "Checked in Rajesh Kumar from ABC Solutions Ltd. Card scanned successfully.", "info", new DateTime(2026, 6, 26, 12, 0, 0, 0, DateTimeKind.Utc), "Satish Singh (Guard)" },
                    { new Guid("22222222-2222-2222-2222-222222222222"), "GPS Office Duty Start", "Employee Shubham Kumar initiated out-of-office GPS Duty Tracking (Destination: Nehru Place).", "info", new DateTime(2026, 6, 26, 11, 50, 0, 0, DateTimeKind.Utc), "System" }
                });

            migrationBuilder.InsertData(
                table: "OfficeDutyLogs",
                columns: new[] { "Id", "Destination", "EmployeeId", "EmployeeName", "Reason", "StartTime", "Status", "StopTime" },
                values: new object[,]
                {
                    { new Guid("33333333-3333-3333-3333-333333333331"), "Nehru Place Client Center", new Guid("00000000-0000-0000-0000-000000000002"), "Shubham Kumar", "Hardware installation & website training for Directors", new DateTime(2026, 6, 26, 11, 0, 0, 0, DateTimeKind.Utc), "Active", null },
                    { new Guid("33333333-3333-3333-3333-333333333332"), "Connaught Place Head Office", new Guid("00000000-0000-0000-0000-000000000003"), "Anita Sharma", "Quarterly HR compliance audit", new DateTime(2026, 6, 26, 11, 30, 0, 0, DateTimeKind.Utc), "Active", null }
                });

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "Department", "Designation", "Email", "FaceRegistered", "FirstName", "IsActive", "LastName", "PasswordHash", "Phone", "PhotoUrl", "Role" },
                values: new object[,]
                {
                    { new Guid("00000000-0000-0000-0000-000000000001"), "Web & IT", "General Manager", "admin@iod.com", true, "Ravi Shankar", true, "Swami", "hashed_admin123", "+91-9988776655", "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150", "Admin" },
                    { new Guid("00000000-0000-0000-0000-000000000002"), "Web & IT", "Software Engineering Intern", "shubham@iod.com", true, "Shubham", true, "Kumar", "hashed_staff123", "+91-9876543210", "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150", "Staff" },
                    { new Guid("00000000-0000-0000-0000-000000000003"), "Human Resources", "HR Lead", "anita.hr@iod.com", false, "Anita", true, "Sharma", "hashed_staff123", "+91-8888777766", "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150", "Staff" },
                    { new Guid("00000000-0000-0000-0000-000000000004"), "Security Operations", "Lobby Security Supervisor", "guard@iod.com", true, "Satish", true, "Singh", "hashed_guard123", "+91-7777666655", "https://images.unsplash.com/photo-1621574539437-4b7cb63120b8?w=150", "SecurityGuard" },
                    { new Guid("00000000-0000-0000-0000-000000000005"), "Corporate Affairs", "Executive Director", "exec@iod.com", true, "Arun", true, "Bajaj", "hashed_staff123", "+91-9999888877", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150", "Staff" },
                    { new Guid("00000000-0000-0000-0000-000000000006"), "Finance & Accounting", "Senior Analyst", "analyst@iod.com", true, "Priya", true, "Menon", "hashed_staff123", "+91-8888999900", "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150", "Staff" },
                    { new Guid("00000000-0000-0000-0000-000000000007"), "Web & IT", "IT Administrator", "itadmin@iod.com", false, "Karthik", true, "Raman", "hashed_staff123", "+91-7777888899", "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150", "Staff" },
                    { new Guid("00000000-0000-0000-0000-000000000008"), "Corporate Affairs", "Board Secretary", "secretary@iod.com", true, "Sneha", true, "Rao", "hashed_staff123", "+91-6666777788", "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150", "Staff" },
                    { new Guid("00000000-0000-0000-0000-000000000009"), "Security Operations", "Security Specialist", "security@iod.com", false, "Vikram", true, "Singh", "hashed_guard123", "+91-5555666677", "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150", "SecurityGuard" }
                });

            migrationBuilder.InsertData(
                table: "WatchlistTargets",
                columns: new[] { "Id", "Email", "FirstName", "FlaggedAt", "LastName", "Phone", "Reason" },
                values: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), "suresh@blacklisted.com", "Suresh", new DateTime(2026, 5, 10, 11, 0, 0, 0, DateTimeKind.Utc), "Mehta", "+91-9000111222", "Disruptive behavior during General Meeting" });

            migrationBuilder.InsertData(
                table: "LocationCoordinates",
                columns: new[] { "Id", "DutyLogId", "Latitude", "Longitude", "Timestamp" },
                values: new object[,]
                {
                    { new Guid("44444444-4444-4444-4444-444444444441"), new Guid("33333333-3333-3333-3333-333333333331"), "QB/etRdYcDZXLNqpWjcoWmomdtE8mEVe7xrbW6poIIw=", "I+pGhbS8BYOYb4W63Co0yQ/3W29DidDn3KE/rs6dnUA=", new DateTime(2026, 6, 26, 11, 10, 0, 0, DateTimeKind.Utc) },
                    { new Guid("44444444-4444-4444-4444-444444444442"), new Guid("33333333-3333-3333-3333-333333333331"), "U3olbJz3ToO3AYMnlQzjogIHOUmoZDYGFMxhzy7w87g=", "TRKPSVtgJCDcdXz4P3c9F37Wl2PBpkW8tBUZsH/FKMw=", new DateTime(2026, 6, 26, 11, 20, 0, 0, DateTimeKind.Utc) },
                    { new Guid("44444444-4444-4444-4444-444444444443"), new Guid("33333333-3333-3333-3333-333333333331"), "+dcORrW56aLSyH/DO4i7jl4cBshOJdbKlzEjE5XbT+s=", "bkvcfdbfQfjt5gWVMS439PvlSpysMC3M89HKw4vn56Y=", new DateTime(2026, 6, 26, 11, 40, 0, 0, DateTimeKind.Utc) },
                    { new Guid("44444444-4444-4444-4444-444444444444"), new Guid("33333333-3333-3333-3333-333333333331"), "cJ/c0WQpc3C1r7zXOUpQ3TICh1OdKJtnJumL57Fexrc=", "+/DcOtgdYX5FQhfg8utX1XNVPTTBrro1r8CZ1T8vjSU=", new DateTime(2026, 6, 26, 11, 55, 0, 0, DateTimeKind.Utc) },
                    { new Guid("44444444-4444-4444-4444-444444444445"), new Guid("33333333-3333-3333-3333-333333333332"), "EIJ6OiezDKnfmSmi7MG/aek1BRLek2rnpxl+naYP8lw=", "p4Uf+g+DK+TbzPR5a9oCjySoauw5H/P9xoq56Ve+i/M=", new DateTime(2026, 6, 26, 11, 35, 0, 0, DateTimeKind.Utc) },
                    { new Guid("44444444-4444-4444-4444-444444444446"), new Guid("33333333-3333-3333-3333-333333333332"), "d3+ABGpZ/u8gEEs41H710HLfjhpdhvlN3tqUI8SZeUo=", "NBV12D/FzlFv1SLesdP8gp30viCSXcH4Z11OiyC1KmI=", new DateTime(2026, 6, 26, 11, 50, 0, 0, DateTimeKind.Utc) }
                });

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceLogs_UserId",
                table: "AttendanceLogs",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_LocationCoordinates_DutyLogId",
                table: "LocationCoordinates",
                column: "DutyLogId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AttendanceLogs");

            migrationBuilder.DropTable(
                name: "AuditLogs");

            migrationBuilder.DropTable(
                name: "LocationCoordinates");

            migrationBuilder.DropTable(
                name: "VisitorPasses");

            migrationBuilder.DropTable(
                name: "WatchlistTargets");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "OfficeDutyLogs");
        }
    }
}
