using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Abp.Application.Services;
using Abp.Dependency;
using Abp.Runtime.Validation;
using Abp.Timing;
using Shouldly;
using Xunit;

namespace Abp.TestBase.Tests.Application.Services
{
    public class Validation_Tests : AbpIntegratedTestBase<AbpKernelModule>
    {
        private readonly IMyAppService _myAppService;

        public Validation_Tests()
        {
            LocalIocManager.Register<IMyAppService, MyAppService>(DependencyLifeStyle.Transient);
            _myAppService = LocalIocManager.Resolve<IMyAppService>();
        }

        [Fact]
        public void Should_Work_Proper_With_Right_Inputs()
        {
            var output = _myAppService.MyMethod(new MyMethodInput { MyStringValue = "test" });
            output.Result.ShouldBe(42);
        }

        [Fact]
        public void Should_Not_Work_With_Wrong_Inputs()
        {
            Assert.Throws<AbpValidationException>(() => _myAppService.MyMethod(new MyMethodInput())); //MyStringValue is not supplied!
            Assert.Throws<AbpValidationException>(() => _myAppService.MyMethod(new MyMethodInput { MyStringValue = "a" })); //MyStringValue's min length should be 3!
        }

        [Fact]
        public void Should_Work_With_Right_Nesned_Inputs()
        {
            var output = _myAppService.MyMethod2(new MyMethod2Input
            {
                MyStringValue2 = "test 1",
                Input1 = new MyMethodInput { MyStringValue = "test 2" },
                DateTimeValue = Clock.Now
            });
            output.Result.ShouldBe(42);
        }

        [Fact]
        public void Should_Not_Work_With_Wrong_Nesned_Inputs_1()
        {
            Assert.Throws<AbpValidationException>(() =>
                _myAppService.MyMethod2(new MyMethod2Input
                {
                    MyStringValue2 = "test 1",
                    Input1 = new MyMethodInput() //MyStringValue is not set
                }));
        }

        [Fact]
        public void Should_Not_Work_With_Wrong_Nesned_Inputs_2()
        {
            Assert.Throws<AbpValidationException>(() =>
                _myAppService.MyMethod2(new MyMethod2Input //Input1 is not set
                {
                    MyStringValue2 = "test 1"
                }));
        }

        [Fact]
        public void Should_Not_Work_With_Wrong_List_Input_1()
        {
            Assert.Throws<AbpValidationException>(() =>
                _myAppService.MyMethod3(
                    new MyMethod3Input
                    {
                        MyStringValue2 = "test 1",
                        ListItems = new List<MyClassInList>
                                    {
                                        new MyClassInList {ValueInList = null}
                                    }
                    }));
        }

        [Fact]
        public void Should_Not_Work_With_Wrong_Array_Input_1()
        {
            Assert.Throws<AbpValidationException>(() =>
                _myAppService.MyMethod3(
                    new MyMethod3Input
                    {
                        MyStringValue2 = "test 1",
                        ArrayItems = new[]
                                     {
                                         new MyClassInList {ValueInList = null}
                                     }
                    }));
        }

        [Fact]
        public void Should_Not_Work_If_Array_Is_Null()
        {
            Assert.Throws<AbpValidationException>(() =>
                _myAppService.MyMethod4(new MyMethod4Input()) //ArrayItems is null!
                );
        }

        [Fact]
        public void Should_Work_If_Array_Is_Null_But_DisabledValidation_For_Method()
        {
            _myAppService.MyMethod4_2(new MyMethod4Input());
        }

        [Fact]
        public void Should_Work_If_Array_Is_Null_But_DisabledValidation_For_Property()
        {
            _myAppService.MyMethod5(new MyMethod5Input());
        }

        [Fact]
        public void Should_Use_IValidatableObject_And_ICustomValidate_On_Validation()
        {
            Assert.Throws<AbpValidationException>(() =>
            {
                _myAppService.MyMethod6(new MyMethod6Input
                {
                    MyStringValue = "test value" //MyIntValue has not set!
                });
            });
        }

        [Fact]
        public void Should_Normalize_Nested_Dtos()
        {
            var input = new MyMethod7Input
            {
                Inner = new MyMethod7Input.MyMethod7InputInner
                {
                    Value = 10
                }
            };

            _myAppService.MyMethod7(input);

            input.Inner.Value.ShouldBe(12);
        }

        [Fact]
        public void Should_Stop_Recursive_Validation_In_A_Constant_Depth()
        {
            _myAppService.MyMethod8(new MyClassWithRecursiveReference { Value = 42 }).Result.ShouldBe(42);
        }

        [Fact]
        public void Should_Allow_Null_For_Nullable_Enums()
        {
            _myAppService.MyMethodWithNullableEnum(null);
        }

        #region Nested Classes

        public interface IMyAppService
        {
            MyMethodOutput MyMethod(MyMethodInput input);
            MyMethodOutput MyMethod2(MyMethod2Input input);
            MyMethodOutput MyMethod3(MyMethod3Input input);
            MyMethodOutput MyMethod4(MyMethod4Input input);
            MyMethodOutput MyMethod4_2(MyMethod4Input input);
            MyMethodOutput MyMethod5(MyMethod5Input input);
            MyMethodOutput MyMethod6(MyMethod6Input input);
            MyMethodOutput MyMethod7(MyMethod7Input input);
            MyMethodOutput MyMethod8(MyClassWithRecursiveReference input);
            void MyMethodWithNullableEnum(MyEnum? value);
        }

        public class MyAppService : IMyAppService, IApplicationService
        {
            public MyMethodOutput MyMethod(MyMethodInput input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public MyMethodOutput MyMethod2(MyMethod2Input input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public MyMethodOutput MyMethod3(MyMethod3Input input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public MyMethodOutput MyMethod4(MyMethod4Input input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            [DisableValidation]
            public MyMethodOutput MyMethod4_2(MyMethod4Input input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public MyMethodOutput MyMethod5(MyMethod5Input input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public MyMethodOutput MyMethod6(MyMethod6Input input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public MyMethodOutput MyMethod7(MyMethod7Input input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public MyMethodOutput MyMethod8(MyClassWithRecursiveReference input)
            {
                return new MyMethodOutput { Result = 42 };
            }

            public void MyMethodWithNullableEnum(MyEnum? value)
            {
                
            }
        }

        public class MyMethodInput
        {
            [Required]
            [MinLength(3)]
            public string MyStringValue { get; set; }
        }

        public class MyMethod2Input
        {
            [Required]
            [MinLength(2)]
            public string MyStringValue2 { get; set; }

            public DateTime DateTimeValue { get; set; }

            [Required]
            public MyMethodInput Input1 { get; set; }
        }

        public class MyMethod3Input
        {
            [Required]
            [MinLength(2)]
            public string MyStringValue2 { get; set; }

            public List<MyClassInList> ListItems { get; set; }

            public MyClassInList[] ArrayItems { get; set; }
        }

        public class MyMethod4Input
        {
            [Required]
            public MyClassInList[] ArrayItems { get; set; }
        }

        public class MyMethod5Input
        {
            [DisableValidation]
            public MyClassInList[] ArrayItems { get; set; }
        }

        public class MyMethod6Input : IValidatableObject, ICustomValidate
        {
            [Required]
            [MinLength(2)]
            public string MyStringValue { get; set; }

            public int MyIntValue { get; set; }

            public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
            {
                if (MyIntValue < 18)
                {
                    yield return new ValidationResult("MyIntValue must be greather than or equal to 18");
                }
            }

            public void AddValidationErrors(CustomValidationContext context)
            {
                //a (meaningless) example of resolving dependency in custom validation
                context.IocResolver.Resolve<IIocManager>().ShouldNotBeNull();
            }
        }

        public class MyMethod7Input : IShouldNormalize
        {
            public MyMethod7InputInner Inner { get; set; }

            public void Normalize()
            {
                Inner.Value++;
            }

            public class MyMethod7InputInner : IShouldNormalize
            {
                public int Value { get; set; }

                public void Normalize()
                {
                    Value++;
                }
            }
        }

        public class MyClassInList
        {
            [Required]
            [MinLength(3)]
            public string ValueInList { get; set; }
        }

        public class MyMethodOutput
        {
            public int Result { get; set; }
        }

        public class MyClassWithRecursiveReference
        {
            public MyClassWithRecursiveReference Reference { get; }

            [Required]
            public int Value { get; set; }

            public MyClassWithRecursiveReference()
            {
                Reference = this;
            }
        }

        public enum MyEnum
        {
            Value1,
            Value2
        }

        #endregion
    }
}
