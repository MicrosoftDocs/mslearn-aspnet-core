using System;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration.AzureKeyVault;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.KeyVault;

namespace ContosoPets.Ui
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.ConfigureAppConfiguration(config => ConfigureKeyVault(config));
                    webBuilder.UseStartup<Startup>();
                });

        private static void ConfigureKeyVault(IConfigurationBuilder config)
        {
            var azureServiceTokenProvider = new AzureServiceTokenProvider();
            var keyVaultClient = new KeyVaultClient(
                new KeyVaultClient.AuthenticationCallback(azureServiceTokenProvider.KeyVaultTokenCallback));

            string keyVaultEndpoint = Environment.GetEnvironmentVariable(
                "ASPNETCORE_HOSTINGSTARTUP__KEYVAULT__CONFIGURATIONVAULT");

            config.AddAzureKeyVault(
                keyVaultEndpoint, keyVaultClient, new DefaultKeyVaultSecretManager());
        }
    }
}
