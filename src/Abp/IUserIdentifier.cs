namespace Abp
{
    /// <summary>
    /// Interface to get a user identifier.
    /// </summary>
    public interface IUserIdentifier
    {
        /// <summary>
        /// Tenant Id. Can be null for host users.
        /// </summary>
        string TenantId { get; }

        /// <summary>
        /// Id of the user.
        /// </summary>
        string UserId { get; }
    }
}
