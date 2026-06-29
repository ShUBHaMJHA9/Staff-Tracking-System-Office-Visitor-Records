using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IodEnterpriseApi.Migrations
{
    /// <inheritdoc />
    public partial class AddOmniAuthFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ActivationCode",
                table: "Users",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CurrentOtp",
                table: "Users",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeviceRegistered",
                table: "Users",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "OtpExpiry",
                table: "Users",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "QrLoginToken",
                table: "Users",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RegisteredDeviceId",
                table: "Users",
                type: "TEXT",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "EIGLfKTrsjfqJF+TJ4Q8aCNTqQuAi1LizHq/Zp8FZBk=", "RrKEFLmHYno3oZTZ1N6odJCypB4jGeat34VqTnrgidk=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "K1IOfMTpfWpHvM9c+MHpbrSZFAMkmaM4oLtqaUP/ahQ=", "IfheQUmiGvGohkj+b8mwv/tubQYvSgJjf71ZO1kv6NA=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "Nrs9iGB/yv4+qL+bBwm4mWcVTwZ2W8yC9GIqrvjy5oY=", "4geTCAvqW2AlKWuF6afwOlT3SKsp3gGEhWiXwEoEQn0=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "GkFJ8ph0smcbEY7RrarmuW3Q9ki6Sh9677L//9OywhQ=", "6ecSeNjzmTNV/xvpqTewKtS4qLUE8jNdr8rmVDuA49c=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "G4CpEgGXkBWg63Xq6PaZa5/egCQGY+aolUWC6hfI2Aw=", "kVcZMpgP6yiNjZsPSwD++iCTZxUz9GCG0XK8kgL+p9E=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "JVQWg4c1EoJV/dPSdtIUnYs6w17vVhRgc4BHKdO0HIc=", "f7CB384Zj7fpBjbzT828NxiniHqvjAr7lfXz6CNUdOI=" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000001"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000002"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000003"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000004"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000005"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000006"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000007"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000008"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000009"),
                columns: new[] { "ActivationCode", "CurrentOtp", "IsDeviceRegistered", "OtpExpiry", "QrLoginToken", "RegisteredDeviceId" },
                values: new object[] { null, null, false, null, null, null });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ActivationCode",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CurrentOtp",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsDeviceRegistered",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "OtpExpiry",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "QrLoginToken",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "RegisteredDeviceId",
                table: "Users");

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444441"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "6ZbJXW4K5zDkWBXykEN64DxhIPHLT+iN+ILlf7NccXo=", "4dyCyjJLJDjm/cSptbfXEhJUtHJEOhvdUDNLgnJ3fxU=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444442"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "5j3TVe4nCAIPFCZLzScqvRez98Xu+UGaK0z7NWGx1y4=", "it2P74cpEbEib/mcU7MGqKaZ9Ii8/A/uMK6vuWlu06E=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444443"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "41W31cdYe0MhT37CLFWkEylXJVNQAtkGBV95GYWYNJU=", "6PeSAft4XjkBj8RWzPwJDzZ9hsjpHqXBrupZRzlUaTA=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "cA2AR9bdfDseIhrcGIcLZbzbaLauPluomVpecZTnSag=", "MIjAH4ZKNLNiYbrkvQnWKnIb4I7ZOXzN7HfyKMMceos=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444445"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "DUdZOJhcNjYLFcq/6TQuo7KUidPMO2Mh1dWZEHo5XCg=", "4CFfo/nOP1KZjK1al3oVgfPJd7w6f4/NsUvsQneq+Ig=" });

            migrationBuilder.UpdateData(
                table: "LocationCoordinates",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444446"),
                columns: new[] { "Latitude", "Longitude" },
                values: new object[] { "SWje5+pFv93ubB1B0PWuNAx+RukcCvlnM5icfzDar2c=", "ru8K8nS6/smSS56mIzdshKfs9bjrr8dSfzSmhdK2n6U=" });
        }
    }
}
