using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sentinel.Identity.Domain.Entities;

namespace Sentinel.Identity.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("tbl_user", "public");

        // Primary Key
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id)
            .HasColumnName("id_us")
            .ValueGeneratedOnAdd();

        // Propiedades
        builder.Property(u => u.Name)
            .HasColumnName("name_us")
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(u => u.LastName)
            .HasColumnName("lastname_us")
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(u => u.Dni)
            .HasColumnName("dni_us")
            .HasMaxLength(10)
            .IsFixedLength()
            .IsRequired();

        builder.Property(u => u.Phone)
            .HasColumnName("phone_us")
            .HasMaxLength(20);

        builder.Property(u => u.Address)
            .HasColumnName("address_us")
            .HasMaxLength(255);

        builder.Property(u => u.Status)
            .HasColumnName("status_us")
            .HasMaxLength(1)
            .IsFixedLength()
            .IsRequired();

        builder.Property(u => u.CreatedAt)
            .HasColumnName("created_at")
            .HasDefaultValueSql("CURRENT_TIMESTAMP")
            .IsRequired();

        builder.Property(u => u.UpdateAt)
            .HasColumnName("update_at");

        builder.Property(u => u.Age)
            .HasColumnName("age_us")
            .IsRequired();

        builder.Property(u => u.PasswordHash)
            .HasColumnName("password_us")
            .HasMaxLength(255)
            .IsRequired();

        builder.Property(u => u.Username)
            .HasColumnName("username_us")
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(u => u.Email)
            .HasColumnName("email_us")
            .HasMaxLength(255)
            .IsRequired();

        builder.Property(u => u.EmailVerified)
            .HasColumnName("email_verified")
            .HasDefaultValue(false)
            .IsRequired();
        

        // Índices únicos
        builder.HasIndex(u => u.Username)
            .IsUnique()
            .HasDatabaseName("ix_tbl_user_username");

        builder.HasIndex(u => u.Email)
            .IsUnique()
            .HasDatabaseName("ix_tbl_user_email");

        builder.HasIndex(u => u.Dni)
            .IsUnique()
            .HasDatabaseName("ix_tbl_user_dni");
    }
}