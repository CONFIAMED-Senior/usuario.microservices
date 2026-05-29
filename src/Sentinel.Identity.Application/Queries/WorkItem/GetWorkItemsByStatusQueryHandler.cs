using AutoMapper;
using MediatR;
using Sentinel.Identity.Application.Commands;
using Sentinel.Identity.Application.DTOs;
using Sentinel.Identity.Domain.Repositories;

namespace Sentinel.Identity.Application.Queries.WorkItem;

public class GetWorkItemsByStatusQueryHandler 
    : IRequestHandler<GetWorkItemsByStatusQuery, ApiResponse<IEnumerable<WorkItemDto>>>
{
    private readonly IUserRepository _repository;
    private readonly IMapper _mapper;

    public GetWorkItemsByStatusQueryHandler(IUserRepository repository, IMapper mapper)
    {
        _repository = repository;
        _mapper = mapper;
    }

    public async Task<ApiResponse<IEnumerable<WorkItemDto>>> Handle(
        GetWorkItemsByStatusQuery request,
        CancellationToken cancellationToken)
    {
        var workItems = await _repository.GetWorkItemsByStatusAsync(request.Status, cancellationToken);
        var dtos = _mapper.Map<IEnumerable<WorkItemDto>>(workItems);

        return ApiResponse<IEnumerable<WorkItemDto>>.SuccessResponse(dtos);
    }
}