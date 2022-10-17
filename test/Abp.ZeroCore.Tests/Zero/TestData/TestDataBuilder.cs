using Abp.ZeroCore.SampleApp.EntityFramework;

namespace Abp.Zero.TestData
{
    public class TestDataBuilder
    {
        private readonly SampleAppDbContext _context;
        private readonly string _tenantId;

        public TestDataBuilder(SampleAppDbContext context, string tenantId)
        {
            _context = context;
            _tenantId = tenantId;
        }

        public void Create()
        {
            new TestRolesBuilder(_context, _tenantId).Create();
            new TestOrganizationUnitsBuilder(_context, _tenantId).Create();

            _context.SaveChanges();
        }
    }
}
