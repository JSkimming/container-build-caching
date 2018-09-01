// Copyright (c) 2018 James Skimming. All rights reserved.

namespace Cbc.Identity
{
    using System;
    using System.Globalization;
    using System.IO;
    using System.Net;
    using System.Net.Http;
    using System.Reflection;
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Builder;
    using Microsoft.AspNetCore.Hosting;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.Mvc.Authorization;
    using Microsoft.EntityFrameworkCore;
    using Microsoft.Extensions.Configuration;
    using Microsoft.Extensions.DependencyInjection;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Converters;
    using Newtonsoft.Json.Serialization;
    using Serilog;
    using Swashbuckle.AspNetCore.Swagger;

    /// <summary>
    /// The start-up class for application configuration and initialization.
    /// </summary>
    public class Startup : IStartup
    {
        private const string CorsPolicyName = "CorsPolicy";

        private readonly ILogger _log;

        /// <summary>
        /// Initializes a new instance of the <see cref="Startup"/> class.
        /// </summary>
        /// <param name="configuration">The <see cref="IConfiguration"/>.</param>
        /// <param name="log">The <see cref="ILogger"/> for the application.</param>
        public Startup(
            IConfiguration configuration,
            ILogger log)
        {
            Configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
            _log = log ?? throw new ArgumentNullException(nameof(log));
        }

        /// <summary>
        /// Gets the <see cref="IConfiguration"/>.
        /// </summary>
        public IConfiguration Configuration { get; }

        /// <summary>
        /// This method gets called by the runtime. Use this method to add services to the container.
        /// </summary>
        /// <param name="services">The <see cref="IServiceCollection" /> to add the service to.</param>
        /// <remarks>
        /// For more information on how to configure your application, visit
        /// https://go.microsoft.com/fwlink/?LinkID=398940.
        /// </remarks>
        /// <returns>The <see cref="IServiceProvider"/>.</returns>
        public IServiceProvider ConfigureServices(IServiceCollection services)
        {
            services.AddMvcCore()
                .SetCompatibilityVersion(CompatibilityVersion.Version_2_1)
                .AddApiExplorer()
                .AddAuthorization()
                .AddJsonFormatters(settings =>
                {
                    var contractResolver = new CamelCasePropertyNamesContractResolver
                    {
                        NamingStrategy =
                        {
                            OverrideSpecifiedNames = false,
                            ProcessDictionaryKeys = false,
                        },
                    };

                    var dateTimeConverter = new IsoDateTimeConverter
                    {
                        // This ensures DateTime and DateTimeOffset all output a Zulu time format..
                        DateTimeFormat = "yyyy-MM-ddTHH:mm:ss.fffffffZ",

                        // Always adjust dates/times to UTC and assume UTC if it's ambiguous.
                        DateTimeStyles = DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal,
                    };

                    settings.ContractResolver = contractResolver;
                    settings.DateTimeZoneHandling = DateTimeZoneHandling.Utc;
                    settings.Converters.Add(dateTimeConverter);
                    settings.Converters.Add(new StringEnumConverter(true));
                })
                .AddCors(options =>
                    options.AddPolicy(CorsPolicyName, builder =>
                    {
                        builder
                            .AllowAnyOrigin()
                            .AllowAnyMethod()
                            .AllowAnyHeader()
                            .SetPreflightMaxAge(TimeSpan.FromDays(1));
                    }));

            services.AddSwaggerGen(options =>
            {
                options.DescribeAllEnumsAsStrings();
                options.DescribeStringEnumsInCamelCase();
                options.SwaggerDoc(
                    "v1",
                    new Info { Title = "CBC Identity API", Version = "v1" });

                string basePath = AppContext.BaseDirectory;
                string apiXmlDocs = Path.Combine(basePath, "Cbc.Identity.xml");
                if (File.Exists(apiXmlDocs))
                {
                    options.IncludeXmlComments(apiXmlDocs);
                }
            });

            services.AddSingleton<IHello, Hello>();

            return services.BuildServiceProvider();
        }

        /// <summary>
        /// This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        /// </summary>
        /// <param name="app">The <see cref="IApplicationBuilder"/>.</param>
        public void Configure(IApplicationBuilder app)
        {
            IHostingEnvironment env = app.ApplicationServices.GetService<IHostingEnvironment>();

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app
                .UseStatusCodePages()
                .UseCors(CorsPolicyName)
                .UseMvc()
                .UseStaticFiles()
                .UseSwagger()
                .UseSwaggerUI(options =>
                {
                    options.SwaggerEndpoint("/swagger/v1/swagger.json", "CBC Identity API V1");
                });
        }
    }
}
