using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sentinel.Identity.Domain.Entities;

namespace Sentinel.Identity.Infrastructure.Persistence.Configurations;

public class UserWorkItemConfiguration : IEntityTypeConfiguration<UserWorkItem>
{
    public void Configure(EntityTypeBuilder<UserWorkItem> entity)
    {
        entity.HasKey(e => e.IdUwi).HasName("pk_tbl_user_work_items");

        entity.Property(e => e.IdUwi).UseIdentityAlwaysColumn();
        entity.Property(e => e.AssignmentDate).HasDefaultValueSql("CURRENT_TIMESTAMP");

        entity.HasOne(d => d.IdUsNavigation).WithMany(p => p.UserWorkItems).HasConstraintName("fk_tbl_user_work_items_user");

        entity.HasOne(d => d.IdWiNavigation).WithMany(p => p.UserWorkItems).HasConstraintName("fk_tbl_user_work_items_work_item");
    }
}