using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sentinel.Identity.Domain.Entities;

namespace Sentinel.Identity.Infrastructure.Persistence.Configurations;

public class WorkItemConfiguration : IEntityTypeConfiguration<WorkItem>
{

    public void Configure(EntityTypeBuilder<WorkItem> builder)
    {
        builder.HasKey(e => e.IdWi).HasName("tbl_work_items_pk");

        builder.Property(e => e.IdWi).UseIdentityAlwaysColumn();
        
    }
    
}