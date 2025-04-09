using System;
using System.Threading.Tasks;
using Abp.Domain.Entities;

namespace Abp.EntityHistory
{
    public static class EntitySnapshotManagerExtensions
    {
        /// <summary>
        /// shortcut of (IEntitySnapshotManager).GetEntitySnapshotAsync &lt;TEntity, int &gt;
        /// </summary>
        public static async Task<EntityHistorySnapshot> GetSnapshotAsync<TEntity>(
            this IEntitySnapshotManager entitySnapshotManager, 
            string id, 
            DateTime snapshotTime)
            where TEntity : class, IEntity<string>
        {
            return await entitySnapshotManager.GetSnapshotAsync<TEntity, string>(id, snapshotTime);
        }
    }
}
