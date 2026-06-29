using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IodEnterpriseApi.Migrations
{
    /// <inheritdoc />
    public partial class AddShiftAttendanceDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "LeaveTime",
                table: "GatePasses",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "CheckedInBy",
                table: "AttendanceLogs",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "CheckedOutBy",
                table: "AttendanceLogs",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "Ts36xW1RDXMn7NrcND5qMpVl6q6WUa8xUJZ9tIiigNg=", "h93Voxxo/YHUy/TNzXnf+gMTQmciZZ9nnUim5JNzpqo=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "qpL4avmEcEmwl+k8tN1rFKW3I4PylINDzfX19En8cjQ=", "uphQnmH6ZlqoQZAtPfOGYPdUv0NovpAaGQpHB/LxYzM=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "N8cfRWIhQI0fS9EadRAfcL7eKVEy6YNYbG+3f1mm9CM=", "4GUmDXGD0ZDQ4rUYO6Pds506CiCYtSXiK1jnAdIqvBc=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "QbVk8ll09f17NIpAcnLdHZk4qPSq4s1O5rx/nzyyZE4=", "C/0D8NMTzDSDjIJekZ9zR/hURN6KSGiN0LFC0Ge68O0=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "pNISNL6m6u/7hYmUWZ95MFKdHhhBxt1KbpqyUEEJ0UA=", "Yg8RvODYBU54k2KtEo87CofPWLyMRs2QQyOgKTLlCh0=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "Yw2DIxHQAnV053aW7CW5KKaWthuGmB12roN7CydkdmY=", "nM1W0v1YkkRlkKHeO62SOFMu1xe5Yw4rdtCjT8r6HBg=" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LeaveTime",
                table: "GatePasses");

            migrationBuilder.DropColumn(
                name: "CheckedInBy",
                table: "AttendanceLogs");

            migrationBuilder.DropColumn(
                name: "CheckedOutBy",
                table: "AttendanceLogs");

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "TJ2Z4qIWctRwN82m1FnMp9/xeA+84h3oSGMmffwm7nk=", "VQUEcweBT77c1u/RIWNhZCz8CpF8c0PBCq9YHPJXq8g=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "OTBH3SsYGkgoJee0GJSCCtbJs0KVm/4cH7zZwF8jjTM=", "2jvlQVtOZxBa8fRy9LoJ96llkafMKO2FIv5h3R7W7WQ=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "hdQL+kHjlDtngTJy3Hsc1dpTwbqVTvCnpbf2TGuQ9cM=", "KWEBK3RIQbNWLwoRcFLA9oSmyNj5u0uyzoi05SwcyIA=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "BZrLSr3iIbqkXR/0C1puKJfu3MbUn9Giu85CAiWB3l8=", "nDlH6DObD19qJzvKxQcXOvokuZOJpEIDWVAV7fxDAa4=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "4VjpXxhOACVBZ4YWIkhJVZwe738TdCHSZOISr7BLHV4=", "XWIWm9awcFQiwu9L3TbdsjOAWRVi8Px6ezIBF940Zf0=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "4Fsjd3toHmzHMqHd4yxk9nz0h1L64jgzgKxwUSJtN4M=", "pe2Lhk7J5edOWlGT6ATcccb+r/NNAKssvMtHdZArwVM=" });
        }
    }
}
