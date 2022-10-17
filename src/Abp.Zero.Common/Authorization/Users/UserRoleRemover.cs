using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.Domain.Uow;
using Abp.Events.Bus.Entities;
using Abp.Events.Bus.Handlers;

namespace Abp.Authorization.Users
{
    /// <summary>
    /// Removes the user from all user roles when a user is deleted.
    /// </summary>
    public class UserRoleRemover :
        IEventHandler<EntityDeletedEventData<AbpUserBase>>,
        ITransientDependency
    {
        private readonly IRepository<UserRole, string> _userRoleRepository;
        private readonly IUnitOfWorkManager _unitOfWorkManager;

        public UserRoleRemover(
            IUnitOfWorkManager unitOfWorkManager, 
            IRepository<UserRole, string> userRoleRepository)
        {
            _unitOfWorkManager = unitOfWorkManager;
            _userRoleRepository = userRoleRepository;
        }
        
        public virtual void HandleEvent(EntityDeletedEventData<AbpUserBase> eventData)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(eventData.Entity.TenantId))
                {
                    _userRoleRepository.Delete(
                        ur => ur.UserId == eventData.Entity.Id
                    );
                }
            });
        }
    }
}
