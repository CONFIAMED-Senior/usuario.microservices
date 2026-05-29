using Microsoft.EntityFrameworkCore;
using Sentinel.Identity.Domain.Entities;

namespace Sentinel.Identity.Infrastructure.Persistence;

public class ApplicationDbContext : DbContext
{
    public DbSet<User> Users { get; set; }
    public DbSet<UserAuditUpdate> UserAuditUpdates { get; set; }
    public DbSet<UserAuditDelete> UserAuditDeletes { get; set; }
    public DbSet<UserWorkItem> UserWorkItems { get; set; }
    public DbSet<WorkItem> WorkItems { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Aplicar todas las configuraciones del ensamblado
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
        
    }
}