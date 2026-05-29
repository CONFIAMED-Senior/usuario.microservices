using AutoMapper;
using MediatR;
using Sentinel.Identity.Application.Commands;
using Sentinel.Identity.Application.DTOs;
using Sentinel.Identity.Domain.Repositories;

namespace Sentinel.Identity.Application.Queries.Users;

public class GetWorkItemsByUserIdQueryHandler 
    : IRequestHandler<GetWorkItemsByUserIdQuery, ApiResponse<IEnumerable<WorkItemDto>>>
{
    private readonly IUserRepository _repository;
    private readonly IMapper _mapper;

    public GetWorkItemsByUserIdQueryHandler(IUserRepository repository, IMapper mapper)
    {
        _repository = repository;
        _mapper = mapper;
    }

    public async Task<ApiResponse<IEnumerable<WorkItemDto>>> Handle(
        GetWorkItemsByUserIdQuery request, 
        CancellationToken cancellationToken)
    {
        var workItems = await _repository.GetWorkItemsByUserIdAsync(request.UserId, cancellationToken);
        var dtos = _mapper.Map<IEnumerable<WorkItemDto>>(workItems);

        return ApiResponse<IEnumerable<WorkItemDto>>.SuccessResponse(dtos);
    }
}