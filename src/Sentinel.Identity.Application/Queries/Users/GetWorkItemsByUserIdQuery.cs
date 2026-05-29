using MediatR;
using Sentinel.Identity.Application.Commands;
using Sentinel.Identity.Application.DTOs;

namespace Sentinel.Identity.Application.Queries.Users;

public record GetWorkItemsByUserIdQuery(int UserId) 
    : IRequest<ApiResponse<IEnumerable<WorkItemDto>>>;