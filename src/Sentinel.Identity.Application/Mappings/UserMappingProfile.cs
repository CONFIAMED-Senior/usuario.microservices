using AutoMapper;
using Sentinel.Identity.Application.DTOs;
using Sentinel.Identity.Application.DTOs.Auth;
using Sentinel.Identity.Domain.Entities;

namespace Sentinel.Identity.Application.Mappings;

public class UserMappingProfile : Profile
{
    public UserMappingProfile()
    {
        CreateMap<User, UserListDto>();
        CreateMap<UserWriteDto, User>();
        
        CreateMap<WorkItem, WorkItemDto>()
            .ConstructUsing(src => new WorkItemDto(
                src.IdWi,
                src.CodeWi,
                src.DescriptionWi,
                src.StatusWi,
                src.Relevance,
                src.CreatedAt,
                src.ExpirationDate
            ));
    }
}