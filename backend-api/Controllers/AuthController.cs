using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using IodEnterpriseApi.Data;
using IodEnterpriseApi.Models;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace IodEnterpriseApi.Controllers
{
    [ApiController]
    [Route("api/v1/auth")]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(ApplicationDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        private async Task<IActionResult> GenerateAuthResponse(User user, string authMethod, string? deviceId = null)
        {
            // Register device if passed
            if (!string.IsNullOrEmpty(deviceId))
            {
                user.RegisteredDeviceId = deviceId;
                user.IsDeviceRegistered = true;
            }

            user.ActiveTokenId = Guid.NewGuid(); // Invalidate old tokens
            
            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtKey = _configuration["Jwt:Key"] ?? "IOD_Global_Enterprise_OMS_Super_Secure_Secret_Key_2026";
            var key = Encoding.ASCII.GetBytes(jwtKey);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Email, user.Email),
                    new Claim(ClaimTypes.Role, user.Role),
                    new Claim("FirstName", user.FirstName),
                    new Claim("LastName", user.LastName),
                    new Claim("Department", user.Department),
                    new Claim("TokenId", user.ActiveTokenId.ToString())
                }),
                Expires = DateTime.UtcNow.AddDays(365),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = _configuration["Jwt:Issuer"] ?? "IodEnterpriseServer",
                Audience = _configuration["Jwt:Audience"] ?? "IodEnterpriseClient"
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var tokenString = tokenHandler.WriteToken(token);

            var audit = new AuditLog
            {
                Timestamp = DateTime.UtcNow,
                User = $"{user.FirstName} {user.LastName} ({user.Role})",
                Action = "User Sign-in",
                Details = $"Successfully authenticated via {authMethod}.",
                Severity = "info"
            };
            _context.AuditLogs.Add(audit);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Token = tokenString,
                Expires = tokenDescriptor.Expires,
                User = new
                {
                    Id = user.Id,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Role = user.Role,
                    Department = user.Department,
                    Designation = user.Designation,
                    PhotoUrl = user.PhotoUrl,
                    FaceRegistered = user.FaceRegistered,
                    IsDeviceRegistered = user.IsDeviceRegistered
                }
            });
        }

        public class LoginRequest
        {
            public string Email { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrEmpty(request.Email) || string.IsNullOrEmpty(request.Password))
                return BadRequest(new { message = "Email and password are required." });

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (user == null || !user.IsActive)
                return Unauthorized(new { message = "Invalid credentials or inactive account." });

            var isPasswordValid = (request.Password == "admin123" && user.PasswordHash == "hashed_admin123") ||
                                  (request.Password == "staff123" && user.PasswordHash == "hashed_staff123") ||
                                  (request.Password == "guard123" && user.PasswordHash == "hashed_guard123");

            if (!isPasswordValid)
            {
                if (user.PasswordHash != request.Password && user.PasswordHash != "hashed_" + request.Password)
                    return Unauthorized(new { message = "Invalid credentials." });
            }

            return await GenerateAuthResponse(user, "Password");
        }

        // --- OMNI-AUTH IMPLEMENTATIONS ---

        public class OtpRequest { public string Phone { get; set; } = string.Empty; }
        public class OtpVerifyRequest { public string Phone { get; set; } = string.Empty; public string Otp { get; set; } = string.Empty; public string DeviceId { get; set; } = string.Empty; }
        public class ActivateRequest { public string Phone { get; set; } = string.Empty; public string ActivationCode { get; set; } = string.Empty; public string DeviceId { get; set; } = string.Empty; }
        public class QrLoginRequest { public string QrToken { get; set; } = string.Empty; public string DeviceId { get; set; } = string.Empty; }

        [HttpPost("request-otp")]
        public async Task<IActionResult> RequestOtp([FromBody] OtpRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Phone == request.Phone);
            if (user == null || !user.IsActive) return BadRequest(new { message = "Mobile number not found." });

            user.CurrentOtp = "1234"; // MOCK OTP AS REQUESTED
            user.OtpExpiry = DateTime.UtcNow.AddMinutes(5);
            await _context.SaveChangesAsync();

            return Ok(new { message = "OTP Sent to registered mobile." }); // In prod this would trigger SMS gateway
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] OtpVerifyRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Phone == request.Phone);
            if (user == null || user.CurrentOtp != request.Otp || user.OtpExpiry < DateTime.UtcNow)
                return Unauthorized(new { message = "Invalid or expired OTP." });

            user.CurrentOtp = null; // Clear OTP
            user.OtpExpiry = null;
            return await GenerateAuthResponse(user, "OTP", request.DeviceId);
        }

        [HttpPost("activate")]
        public async Task<IActionResult> Activate([FromBody] ActivateRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Phone == request.Phone && u.ActivationCode == request.ActivationCode);
            if (user == null || string.IsNullOrEmpty(request.ActivationCode))
                return Unauthorized(new { message = "Invalid Activation Code or Mobile Number." });

            user.ActivationCode = null; // Destroy code (one-time use)
            return await GenerateAuthResponse(user, "Activation Token", request.DeviceId);
        }

        [HttpPost("qr-login")]
        public async Task<IActionResult> QrLogin([FromBody] QrLoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.QrLoginToken == request.QrToken);
            if (user == null || string.IsNullOrEmpty(request.QrToken))
                return Unauthorized(new { message = "Invalid or expired QR Token." });

            // Optional: You could nullify the QR token here if it's meant to be one-time use
            return await GenerateAuthResponse(user, "QR Code Scan", request.DeviceId);
        }

        [HttpPost("verify-face")]
        [Authorize] // Requires valid JWT from OTP/QR step
        public async Task<IActionResult> VerifyFace(IFormFile faceImage)
        {
            if (faceImage == null || faceImage.Length == 0)
                return BadRequest(new { message = "No face image uploaded." });

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var user = await _context.Users.FindAsync(Guid.Parse(userIdClaim.Value));
            if (user == null) return Unauthorized();
            
            if (string.IsNullOrEmpty(user.PhotoUrl))
                return BadRequest(new { message = "User does not have a registered profile photo to match against." });

            try
            {
                using var client = new HttpClient();
                using var form = new MultipartFormDataContent();
                // We use the local Python AI service instead of Face++
                form.Add(new StringContent(user.PhotoUrl ?? ""), "image_url2");

                using var stream = faceImage.OpenReadStream();
                var fileContent = new StreamContent(stream);
                fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(faceImage.ContentType);
                form.Add(fileContent, "image_file1", faceImage.FileName);

                var response = await client.PostAsync("http://127.0.0.1:5125/compare", form);
                var responseString = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    return BadRequest(new { message = "Face matching API failed.", details = responseString });
                }

                // Parse Face++ JSON response
                using var doc = System.Text.Json.JsonDocument.Parse(responseString);
                var root = doc.RootElement;

                if (root.TryGetProperty("confidence", out var confidenceElement))
                {
                    double confidence = confidenceElement.GetDouble();
                    // Generally, > 80 is a strong match for Face++
                    if (confidence < 80.0)
                    {
                        return BadRequest(new { message = $"Face did not match profile photo. Confidence: {confidence:F1}%" });
                    }
                }
                else
                {
                    if (root.TryGetProperty("error_message", out var err))
                    {
                        return BadRequest(new { message = "API Error: " + err.GetString() });
                    }
                    return BadRequest(new { message = "No face detected in one of the images." });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error contacting Face Matching service.", error = ex.Message });
            }

            user.FaceRegistered = true;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Face verified successfully", matched = true });
        }

        // GET /auth/me — returns fresh profile for currently logged-in user
        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> GetMe()
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
                return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "User not found." });

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                firstName = user.FirstName,
                lastName = user.LastName,
                role = user.Role,
                department = user.Department,
                designation = user.Designation,
                photoUrl = user.PhotoUrl,
                phone = user.Phone,
                faceRegistered = user.FaceRegistered,
                isDeviceRegistered = user.IsDeviceRegistered
            });
        }
    }
}
