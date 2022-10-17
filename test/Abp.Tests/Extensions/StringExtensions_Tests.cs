using System;
using System.Globalization;
using System.Linq;
using Abp.Extensions;
using Abp.Localization;
using Shouldly;
using Xunit;

namespace Abp.Tests.Extensions
{
    public class StringExtensions_Tests
    {
        [Fact]
        public void EnsureEndsWith_Test()
        {
            //Expected use-cases
            "Test".EnsureEndsWith('!').ShouldBe("Test!");
            "Test!".EnsureEndsWith('!').ShouldBe("Test!");
            @"C:\test\folderName".EnsureEndsWith('\\').ShouldBe(@"C:\test\folderName\");
            @"C:\test\folderName\".EnsureEndsWith('\\').ShouldBe(@"C:\test\folderName\");

            //Case differences
            "TurkeY".EnsureEndsWith('y').ShouldBe("TurkeYy");
            "TurkeY".EnsureEndsWith('y', StringComparison.OrdinalIgnoreCase).ShouldBe("TurkeY");

            //Edge cases for Turkish 'i'.
            "TAKSİ".EnsureEndsWith('i', true, new CultureInfo("tr-TR")).ShouldBe("TAKSİ");
            "TAKSİ".EnsureEndsWith('i', false, new CultureInfo("tr-TR")).ShouldBe("TAKSİi");
        }

        [Fact]
        public void EnsureStartsWith_Test()
        {
            //Expected use-cases
            "Test".EnsureStartsWith('~').ShouldBe("~Test");
            "~Test".EnsureStartsWith('~').ShouldBe("~Test");

            //Case differences
            "Turkey".EnsureStartsWith('t').ShouldBe("tTurkey");
            "Turkey".EnsureStartsWith('t', StringComparison.OrdinalIgnoreCase).ShouldBe("Turkey");

            //Edge cases for Turkish 'i'.
            "İstanbul".EnsureStartsWith('i', true, new CultureInfo("tr-TR")).ShouldBe("İstanbul");
            "İstanbul".EnsureStartsWith('i', false, new CultureInfo("tr-TR")).ShouldBe("iİstanbul");
        }

        [Fact]
        public void ToPascalCase_Test()
        {
            (null as string).ToPascalCase().ShouldBe(null);
            "helloWorld".ToPascalCase().ShouldBe("HelloWorld");
            "istanbul".ToPascalCase().ShouldBe("Istanbul");
            "istanbul".ToPascalCase(new CultureInfo("tr-TR")).ShouldBe("İstanbul");
        }

        [Fact]
        public void ToCamelCase_Test()
        {
            (null as string).ToCamelCase().ShouldBe(null);
            "HelloWorld".ToCamelCase().ShouldBe("helloWorld");
            "Istanbul".ToCamelCase().ShouldBe("istanbul");
            "Istanbul".ToCamelCase(new CultureInfo("tr-TR")).ShouldBe("ıstanbul");
            "İstanbul".ToCamelCase(new CultureInfo("tr-TR")).ShouldBe("istanbul");
        }

        [Fact]
        public void ToSentenceCase_Test()
        {
            (null as string).ToSentenceCase().ShouldBe(null);
            "HelloWorld".ToSentenceCase().ShouldBe("Hello world");

            using (CultureInfoHelper.Use("en-US"))
            {
                "HelloIsparta".ToSentenceCase().ShouldBe("Hello isparta");
            }

            "HelloIsparta".ToSentenceCase(new CultureInfo("tr-TR")).ShouldBe("Hello ısparta");
        }

        [Fact]
        public void Right_Test()
        {
            const string str = "This is a test string";

            str.Right(3).ShouldBe("ing");
            str.Right(0).ShouldBe("");
            str.Right(str.Length).ShouldBe(str);
        }

        [Fact]
        public void Left_Test()
        {
            const string str = "This is a test string";

            str.Left(3).ShouldBe("Thi");
            str.Left(0).ShouldBe("");
            str.Left(str.Length).ShouldBe(str);
        }

        [Fact]
        public void NormalizeLineEndings_Test()
        {
            const string str = "This\r\n is a\r test \n string";
            var normalized = str.NormalizeLineEndings();
            var lines = normalized.SplitToLines();
            lines.Length.ShouldBe(4);
        }

        [Fact]
        public void NthIndexOf_Test()
        {
            const string str = "This is a test string";

            str.NthIndexOf('i', 0).ShouldBe(-1);
            str.NthIndexOf('i', 1).ShouldBe(2);
            str.NthIndexOf('i', 2).ShouldBe(5);
            str.NthIndexOf('i', 3).ShouldBe(18);
            str.NthIndexOf('i', 4).ShouldBe(-1);
        }

        [Fact]
        public void Truncate_Test()
        {
            const string str = "This is a test string";
            const string nullValue = null;

            str.Truncate(7).ShouldBe("This is");
            str.Truncate(0).ShouldBe("");
            str.Truncate(100).ShouldBe(str);

            nullValue.Truncate(5).ShouldBe(null);
        }

        [Fact]
        public void TruncateWithPostFix_Test()
        {
            const string str = "This is a test string";
            const string nullValue = null;

            str.TruncateWithPostfix(3).ShouldBe("...");
            str.TruncateWithPostfix(12).ShouldBe("This is a...");
            str.TruncateWithPostfix(0).ShouldBe("");
            str.TruncateWithPostfix(100).ShouldBe(str);

            nullValue.Truncate(5).ShouldBe(null);

            str.TruncateWithPostfix(3, "~").ShouldBe("Th~");
            str.TruncateWithPostfix(12, "~").ShouldBe("This is a t~");
            str.TruncateWithPostfix(0, "~").ShouldBe("");
            str.TruncateWithPostfix(100, "~").ShouldBe(str);

            nullValue.TruncateWithPostfix(5, "~").ShouldBe(null);
        }

        [Fact]
        public void RemovePostFix_Tests()
        {
            //null case
            (null as string).RemovePreFix("Test").ShouldBeNull();

            //Simple case
            "MyTestAppService".RemovePostFix("AppService").ShouldBe("MyTest");
            "MyTestAppService".RemovePostFix("Service").ShouldBe("MyTestApp");

            //Multiple postfix (orders of postfixes are important)
            "MyTestAppService".RemovePostFix("AppService", "Service").ShouldBe("MyTest");
            "MyTestAppService".RemovePostFix("Service", "AppService").ShouldBe("MyTestApp");

            //Unmatched case
            "MyTestAppService".RemovePostFix("Unmatched").ShouldBe("MyTestAppService");
        }

        [Fact]
        public void RemovePreFix_Tests()
        {
            "Home.Index".RemovePreFix("NotMatchedPostfix").ShouldBe("Home.Index");
            "Home.About".RemovePreFix("Home.").ShouldBe("About");
        }

        [Fact]
        public void ToEnum_Test()
        {
            "MyValue1".ToEnum<MyEnum>().ShouldBe(MyEnum.MyValue1);
            "MyValue2".ToEnum<MyEnum>().ShouldBe(MyEnum.MyValue2);
        }

        private enum MyEnum
        {
            MyValue1,
            MyValue2
        }
    }
}
