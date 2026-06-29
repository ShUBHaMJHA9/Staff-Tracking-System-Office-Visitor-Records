using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IodEnterpriseApi.Migrations
{
    /// <inheritdoc />
    public partial class AddVisitorCardAndDesignation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Designation",
                table: "VisitorPasses",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "VisitorCardId",
                table: "VisitorPasses",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "Ufb22dJMHXyp8I8vQu+5JoAM3SgSQdeLknfp2OO2P6A=", "XVlVrce2TJMTrBdNi57KhC94lPTrwqF29pKtN9NRYFg=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "g5k5/tNe+yOSuiloF24WBS27aj+FlDUJhUPQX/daTpg=", "PHkbIPi5nD+7Vpv9Z1j5w8kHRi9zf/Rdx56PK2aTZYI=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "/gf/TLqlmgNfnAg9vfGVZWhKEMHEcYxGqVXU4qFp+wQ=", "r5MNXgvyLypcV4AnKpeMfe6tH9JlPO3zj6irR5m5G5E=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "jb5HPQsFOBxhzvl/SrTl1CLqPrxp2v75yHVj8/LdwmM=", "sKgG8XWOyBsuZIVeHlJLPp73enV3YV0H967Jv0+dW7E=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "mcjsAjX6hAVz8vzxWQ5lxg5wzLIuEj2zflUKl30FZ0E=", "72K5toUJn2sRLQJ69GcpvmXEgaQdOOCS7F5Nfe5KCvw=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "ElYvqleCe8G5o49Jhy4+PJlld+nt821T/wm+THUMzes=", "pOMR+mXP99+Harz7dfT18CzBSpFMgBlL7F/1iSrzsjc=" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Designation",
                table: "VisitorPasses");

            migrationBuilder.DropColumn(
                name: "VisitorCardId",
                table: "VisitorPasses");

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "LBowWGYKNMVrPW+jqXFH8Z+rsUXNSEcLOM7D1kp1eUU=", "1rx8wcioT2SqbT0MZBAgNdC3eBEvvb2z0v/pJ47yHBE=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "ydtKzqPKF6XLynNC70qJkKiIPYYvdJc+tRcqdfKZ26M=", "5YzRKqhzK+nyYdxrIKlJFL9ALxu47xwm+an/VIwyf2Y=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "wBoxac1nBOIsjIO6/BjRu11caFWijBzM8FRX2NoPAiY=", "1PRK/W5KyAcUwUP8FHwUR9nE1IRdssgiR2PoLnG0GUc=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "qNtZ7hZPoxVwMqSHqu0Pynu+qT0e5ezYMhgAqxc7AfM=", "227cuwvOidGfODvxmtABy2IEl4WYW8h0bTq+lVPatNU=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "TaaFIF+7n0AH+6HqOLREaT3KApDAV6XhbEwWl1R/EdI=", "Gns0yaxOltiLXpCCszs5Dh1qN4NsTYOFxDBquwGWWiE=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "sJ3FXyTB3KYzGbL1QoFfd1NDRERb5Wo03Rw2qsbS/Yg=", "OGh6zngqQgGoBQ4oL97i0V8tUi/33wwTMtUmyWHD23g=" });
        }
    }
}
