using System.ComponentModel.DataAnnotations.Schema;

namespace Sentinel.Identity.Domain.Entities;

public class User : BaseEntity
{
    public string Name { get; private set; }
    public string LastName { get; private set; }
    public string Dni { get; private set; }
    public string? Phone { get; private set; }
    public string? Address { get; private set; }
    public int Age { get; private set; }
    public string PasswordHash { get; private set; }
    public string Username { get; private set; }
    public string Email { get; private set; }
    public bool EmailVerified { get; private set; }
    
    public virtual ICollection<UserWorkItem> UserWorkItems { get; set; } = new List<UserWorkItem>();

    

    private User() { }

    public static User Create(string name, string lastName, string dni, int age, 
        string username, string email, string passwordHash, string? phone = null, string? address = null)
    {
        return new User
        {
            Name = name,
            LastName = lastName,
            Dni = dni,
            Age = age,
            Username = username,
            Email = email,
            PasswordHash = passwordHash,
            Phone = phone,
            Address = address,
            EmailVerified = false,
        };
    }

    public void Update(string name, string lastName, string dni, int age, 
        string username, string email, string? phone, string? address)
    {
        Name = name;
        LastName = lastName;
        Dni = dni;
        Age = age;
        Username = username;
        Email = email;
        Phone = phone;
        Address = address;
        MarkAsUpdated();
    }

    public void UpdatePassword(string passwordHash)
    {
        PasswordHash = passwordHash;
        MarkAsUpdated();
    }

    public void VerifyEmail()
    {
        EmailVerified = true;
        MarkAsUpdated();
    }
}