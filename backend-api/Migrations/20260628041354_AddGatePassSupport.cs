using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IodEnterpriseApi.Migrations
{
    /// <inheritdoc />
    public partial class AddGatePassSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "GatePasses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    UserId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Reason = table.Column<string>(type: "TEXT", nullable: false),
                    RequestTime = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ApprovalStatus = table.Column<string>(type: "TEXT", nullable: false),
                    ApprovedBy = table.Column<string>(type: "TEXT", nullable: false),
                    ApprovedTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    PassCode = table.Column<string>(type: "TEXT", nullable: false),
                    IsUsed = table.Column<bool>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GatePasses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GatePasses_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "hVEHQOQo6HR7nzcqSDj7aiYHZAOug6qzjmj3ZoVDYwk=", "RqQhuovxWbRgoBKE6k5rwjZ7cLoFQ8fE8WUNH/WwRAk=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "1HOTfPOGT9zR6exB/+mTeGbdRnca7Gl+wYvnemJ3SaI=", "urRWC2lG/PMShMUv5H8+wQFp1PngUWFA2ET0AFbuQpA=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "u9IhZg7lPNEwevPTHCw800exMo/Ya6/mFMOo7usJoNc=", "a0zIjMKPlXAu8NQVhyrSaTBEN+kHPw6hEl8EJhMJqC8=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "4bE7kGZi+KGzf6SPIVfPELpuMIcSUcY7EluZnPgTvuc=", "Wo7oGpgRanD60f2QgaZ876NLPCB0ZktCN9mPFRz3Crc=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "/clsZwS3eMJARPzo7V13ScYaWxyoyT8M8a54U/3ices=", "m0y4hhBzXbbjI4v+pLHpXUKF30l9WjThCKY+3mfdgrI=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "nysJy/4XAQEsWjwhyjfEVW4lqQA1q0llexd7f1629Go=", "m4/HaVvSRlUOjygvXlvKpXVnD3Sw92LJzgC/QkUhvK8=" });

            migrationBuilder.CreateIndex(
                name: "IX_GatePasses_UserId",
                table: "GatePasses",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "GatePasses");

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "kJkLoHEpcAyLaBxOAKcygXl3OyqSSb3J+qac/EHWjWo=", "1/AjvwqyWzKbjDZ/rgZZvPnPbFkEoghc1hDJBpPOC1U=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "t9q/gOjcQqI84djwdHJxeSi9eXnMcib6Tm0SWOUfMTs=", "B29Ao9arcyT2vCOPTEmzRTqk0RzA31JxXr+5OfzX/c8=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "4+31NwyLZfRFikpYNeQGtXxmV4jYrQrfGeP1c6I4HWs=", "HTSDZtlTwIeIubjiLu/GsyoQMwogBslSeZMY4DyVX6Y=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "DsM61rx27S18FEUWW38s5hxQhwDVNtrNPXSTAPxg40c=", "5mvr04JgTlBhxORqgkR/Msx1UOuVZAR9OT1nmzSH+3c=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "u1pEZAQKSOZrv6yQXU3TLAjqkt+Bc10Pcxgf+MsYk7g=", "UEDSroxLFeGRyz0UuCdIVCYI2NuW4Rcbvx18kzWrLJg=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "UkcB5BtoMe/m3H/FW184rO0uXvi51Aj3u7mfacHvuuI=", "4KEyXbly4jOb+aSXjJRjsmIdovMu4T6SH53HtXH+RUs=" });
        }
    }
}
