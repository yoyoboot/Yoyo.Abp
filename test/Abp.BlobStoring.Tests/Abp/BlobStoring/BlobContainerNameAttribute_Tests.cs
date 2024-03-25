using Abp.BlobStoring.Tests.Abp.BlobStoring.TestObjects;
using Shouldly;
using Xunit;

namespace Abp.BlobStoring.Tests.Abp.BlobStoring
{
    public class BlobContainerNameAttribute_Tests
    {
        [Fact]
        public void Should_Get_Specified_Name()
        {
            BlobContainerNameAttribute
                .GetContainerName<TestContainer2>()
                .ShouldBe("Test2");
        }

        [Fact]
        public void Should_Get_Full_Class_Name_If_Not_Specified()
        {
            BlobContainerNameAttribute
                .GetContainerName<TestContainer1>()
                .ShouldBe(typeof(TestContainer1).FullName);
        }
    }
}
