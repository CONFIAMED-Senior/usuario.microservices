using MediatR;
using Sentinel.Identity.Application.Commands;
using Sentinel.Identity.Application.DTOs;

namespace Sentinel.Identity.Application.Queries.WorkItem;

public record GetWorkItemsByStatusQuery(char Status) 
    : IRequest<ApiResponse<IEnumerable<WorkItemDto>>>;