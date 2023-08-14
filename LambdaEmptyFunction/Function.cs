using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using MediatR;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace LambdaEmptyFunction;

public record Casing(string Lower, string Upper);

public class Function
{
    public Casing FunctionHandler(string input, ILambdaContext context)
    {
        return new Casing(input.ToLower(), input.ToUpper());
    }
    
    
    // custom code
    private readonly IServiceProvider _serviceProvider;
    private readonly IConfiguration _configuration;
    public Function()
    {
        var config = ConfigureAppConfiguration();
        _configuration = config;
        _serviceProvider = ConfigureServices(config);
    }

    private static IConfiguration ConfigureAppConfiguration() => new ConfigurationBuilder()
        .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
        .Build();

    private static IServiceProvider ConfigureServices(IConfiguration config)
    {
        var services = new ServiceCollection();
        
        services.AddMediatR(x =>
        {
            x.RegisterServicesFromAssemblyContaining<Function>();
        });
        
        services.AddDefaultAWSOptions(config.GetAWSOptions());

        return services.BuildServiceProvider();
    }
    
    public async Task SqsFunctionHandler(SQSEvent evnt, ILambdaContext context)
    {
        foreach (var message in evnt.Records)
        {
            using var scope = _serviceProvider.CreateScope();
            var request = new TestRequest(message.Body);
            var mediator = scope.ServiceProvider.GetRequiredService<IMediator>();
            var result = await mediator.Send(request);
            context.Logger.LogInformation(result);
        }
    }
}

public record TestRequest(string Message) : IRequest<string>;

public class TestRequestHandler : IRequestHandler<TestRequest, string>
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<TestRequestHandler> _logger;

    public TestRequestHandler(IConfiguration configuration)
    {
        _configuration = configuration;
        
        using var loggerFactory = LoggerFactory.Create(builder =>
        {
            builder.AddConsole();
        });
        var logger = loggerFactory.CreateLogger<TestRequestHandler>();
        logger.LogInformation("Logger registered");
        
        _logger = logger;
    }

    public Task<string> Handle(TestRequest request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Message: {Message}", request.Message);

        var testValue = _configuration["TestKey"];
        return testValue is null
            ? Task.FromResult("Configuration is missing")
            : Task.FromResult(testValue);
    }
}