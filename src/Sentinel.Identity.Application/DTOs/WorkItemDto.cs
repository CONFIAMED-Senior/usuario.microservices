namespace Sentinel.Identity.Application.DTOs;

public record WorkItemDto(
    int Id,
    string? Code,
    string? Description,
    char? Status,
    int? Relevance,
    DateTime? CreatedAt,
    DateTime? ExpirationDate
);