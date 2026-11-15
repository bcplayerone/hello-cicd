var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "local";

app.MapGet("/", () => $"Hello from hello-cicd, version {version}");
app.MapGet("/health", () => Results.Ok(new { status = "ok", version }));

app.Run();