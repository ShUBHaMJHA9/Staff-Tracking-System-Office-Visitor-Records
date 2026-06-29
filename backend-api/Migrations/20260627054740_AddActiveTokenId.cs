using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IodEnterpriseApi.Migrations
{
    /// <inheritdoc />
    public partial class AddActiveTokenId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ActiveTokenId",
                table: "Users",
                type: "TEXT",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "JwEwxge7272vq23qjQKn3eg1L5hDfNhzq2fr++B8/QQ=", "DFlpLbuhPWut1rh0HJ6Es1IBr/rJROzyG/ZiWAZffW4=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "vvmQyiQVesITZL23RbtPMnuVEUrClonkOdOTxpoO0xA=", "M0Q7mzIgQ5zT4tbjcqxfWjKyWk5o0uv+59l8BjVvEV4=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "b/0/OrvMvE0O1J+N9s67JTs3ROugqCs1Vs7tLq2ftk4=", "QZ7qxPzOz4Y8Cgy98HwGENyz+bZZOI8PuljJMZf/JvM=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "S1NEqjxMFURrWfiG+ZlqjyRk3/mREoao17nWYeEcMtI=", "cBF1qY1v5ilFy2ZI5z8T+DtpIt4ig3wMtyew1In5QVc=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "e0sA0WWecydLkVKTlwAppVUaGPKQsdVnzX5Ojkl6AdM=", "lBAVM6F2YswJga742JA8350TK0/GHoFQN0syGqz+64s=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "IG4OPRBXG1Olg4XGcolwshccc31nhGEZzNUGCoL/HcE=", "CIcUPsHrOPlGYNI3HGZbfDYBVyhFTMhJZw8S6mxhkeQ=" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000001"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000002"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000003"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000004"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000005"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000006"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000007"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000008"),
                column: "ActiveTokenId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000009"),
                column: "ActiveTokenId",
                value: null);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ActiveTokenId",
                table: "Users");

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "BdP37sEN2ojfbd/9iac0YUidam4xRBZdisVw/3seWKg=", "j/e58duOJD2iFhhzzRutUMvTtGUkNCna7MkzNDM/h1A=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "dwi5d6ROa06FDc5IJ+/5hZX6iFJni8jhkzE3krL4eD8=", "liJih+GSeob/dx1r4dnKp0zWUpXlFr3cnUmKtn5wUa0=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "M2Z8mF5bPixlXmARwWcQ4N7JEByCJ56zEAofWJLYwQE=", "uaNxgcEY0v/FjmshX5YIE4+0KLXcc/eVmPFjW7GjeYI=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "1lOzMLOKLD9y4xB8VmYWT1vzZWNwLuQhxpOWcBZc1vM=", "FBhEJEGeqojv+NQmWcNpWyiEU66OAHCvPbsr1q2zclc=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "3q6tTteJ5hiylczmqE2m5mQyoXMH/4vMsvrv0E6qAXY=", "MnX/OPUTegvx6cJIVSYdpdC8PuWSOvLOxQA+FSC9elY=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "k3xev7o6uQji7a6t3N8dJE48QKarxJ/yL+f0awrJktY=", "4fxm5T65jrG9mQ6h0N+1updMTkDu7yztGKPQKF+Y9/w=" });
        }
    }
}
