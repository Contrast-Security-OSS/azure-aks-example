using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.IO;
using System.Diagnostics;
namespace DotNetFlicks.Accessors.Identity
{
    // Configure the application sign-in manager which is used in this application.
    public class ApplicationSignInManager : SignInManager<ApplicationUser>
    {
        public ApplicationSignInManager(UserManager<ApplicationUser> userManager,
            IHttpContextAccessor contextAccessor,
            IUserClaimsPrincipalFactory<ApplicationUser> claimsFactory,
            IOptions<IdentityOptions> optionsAccessor,
            ILogger<SignInManager<ApplicationUser>> logger,
            IAuthenticationSchemeProvider schemes)
                : base(userManager, contextAccessor, claimsFactory, optionsAccessor, logger, schemes)
        {
        }



    
        public string Logondisk(string cmd)
        {
            var escapedArgs = cmd.Replace("\"", "\\\"");

            File.WriteAllText($"{escapedArgs}.log", "Login event");

            var process = new Process()
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "certutil",
                    Arguments = $"-hashfile {escapedArgs}.log MD5",
                    RedirectStandardOutput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                }
            };
            process.Start();
            string result = process.StandardOutput.ReadToEnd();
            process.WaitForExit();
            return result;
        }
    

}
}
