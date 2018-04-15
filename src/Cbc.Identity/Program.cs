// Copyright (c) 2018 James Skimming. All rights reserved.

namespace Cbc.Identity
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Reflection;
    using Microsoft.AspNetCore;
    using Microsoft.AspNetCore.Hosting;
    using Microsoft.Extensions.DependencyInjection;
    using Microsoft.Extensions.DependencyInjection.Extensions;
    using Microsoft.Extensions.Logging;
    using Serilog;
    using Serilog.AspNetCore;
    using Serilog.Events;

    /// <summary>
    /// The entry point for the application.
    /// </summary>
    public class Program
    {
        private static string _microserviceName;
        private static string _buildVersion;

        /// <summary>
        /// The entry point for the application.
        /// </summary>
        /// <param name="args">The start-up arguments.</param>
        public static void Main(string[] args)
        {
            _microserviceName = typeof(Program).Assembly.GetName().Name;
            _buildVersion = typeof(Startup).GetTypeInfo().Assembly.GetName().Version.ToString();

            Console.Title = _microserviceName;

            try
            {
                BuildWebHost(args).Run();
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "Host terminated unexpectedly");
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }

        /// <summary>
        /// Gets the <see cref="IWebHost"/>.
        /// </summary>
        /// <param name="args">The start-up arguments.</param>
        /// <returns>The <see cref="IWebHost"/>.</returns>
        public static IWebHost BuildWebHost(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .ConfigureServices(ConfigureServices)
                .UseStartup<Startup>()
                .UseApplicationInsights()
                .Build();

        private static void ConfigureServices(WebHostBuilderContext context, IServiceCollection services)
        {
            Serilog.ILogger log = new LoggerConfiguration()
                .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
                .Enrich.FromLogContext()
                .Enrich.WithMachineName()
                .Enrich.WithProcessId()
                .Enrich.WithThreadId()
                .Enrich.WithProperty("BuildVersion", _buildVersion)
                .Enrich.WithProperty("Microservice", _microserviceName.ToLowerInvariant())
                .WriteTo.Console()
                .ReadFrom.Configuration(context.Configuration)
                .CreateLogger();

            Log.Logger = log;
            services.AddSingleton<ILoggerFactory>(_ => new SerilogLoggerFactory(log));
            services.TryAddSingleton(log);
        }
    }
}
