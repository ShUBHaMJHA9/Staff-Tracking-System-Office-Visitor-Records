// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\backend-api\Program.cs
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using IodEnterpriseApi.Data;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// 1. Configure DB Context (PostgreSQL with InMemory fallback for testing)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Data Source=enterprise.db;Cache=Shared";

builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseSqlite(connectionString);
    options.ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
});

// 2. Configure JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? "IOD_Global_Enterprise_OMS_Super_Secure_Secret_Key_2026";
var key = Encoding.ASCII.GetBytes(jwtKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false; // Dev setting
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "IodEnterpriseServer",
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"] ?? "IodEnterpriseClient",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
    
    // Check ActiveTokenId to enforce Single Device Policy
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var dbContext = context.HttpContext.RequestServices.GetRequiredService<ApplicationDbContext>();
            var userIdStr = context.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var tokenIdStr = context.Principal?.FindFirst("TokenId")?.Value;

            if (Guid.TryParse(userIdStr, out Guid userId))
            {
                var user = await dbContext.Users.FindAsync(userId);
                if (user == null || user.ActiveTokenId.ToString() != tokenIdStr)
                {
                    // Token is invalid because a newer login exists (or user deleted)
                    context.Fail("Session expired. Logged in from another device.");
                }
            }
            else
            {
                context.Fail("Invalid user claims.");
            }
        }
    };
});

// 3. Configure CORS Policies to link the React Admin Panel (Vite Default Port 5173)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAdminPortal", policy =>
    {
        policy.WithOrigins("http://localhost:5173", "http://localhost:5174", "http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi(); // .NET 9 OpenAPI Support

var app = builder.Build();

// 4. Database Initialization and Seeding Trigger
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    // Auto-apply pending migrations (which creates the DB if missing)
    context.Database.Migrate();
    
    // Enable WAL mode for high read/write concurrency
    context.Database.ExecuteSqlRaw("PRAGMA journal_mode=WAL;");
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseStaticFiles();
app.UseHttpsRedirection();

// Apply CORS Policy
app.UseCors("AllowAdminPortal");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.MapGet("/test", () => Results.Ok(new { status = "Backend is Live!" }));

app.Run();
