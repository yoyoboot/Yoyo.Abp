# Yoyo.Abp

<p align="center">
  <a href="./README.md">English</a> |
  <a href="./README_CN.md">简体中文</a>  
</p>

[![NuGet Version](https://img.shields.io/nuget/v/Yoyo.Abp)](https://www.nuget.org/packages/Yoyo.Abp)
[![NuGet Downloads](https://img.shields.io/nuget/dt/Yoyo.Abp?style=flat-square&logo=nuget)](https://www.nuget.org/packages/Yoyo.Abp)
![GitHub last commit](https://img.shields.io/github/last-commit/yoyoboot/yoyo.abp)
![GitHub Release Date](https://img.shields.io/github/release-date/yoyoboot/yoyo.abp)

Welcome to the `Yoyo.Abp` repository! This project is derived from the [ASP.NET Boilerplate](https://github.com/aspnetboilerplate/aspnetboilerplate) framework and has been improved, mainly by updating the default type of entity primary keys from `int` to `string`. We are excited to announce the launch of the [Yoyo.Abp](https://github.com/YoYoBoot/Yoyo.Abp) project, a major update that not only enhances the flexibility and extensibility of the system, but also inherits the power and ease of use of the original `ABP` framework.

This project is not being rolled out at the drop of a hat, we have already used it in a number of internal and commercial projects, so you are not a guinea pig, we have tailored this to our own needs and believe that the entire development community will benefit from this change.

By utilizing the `string` type primary key, our projects have been able to adapt to a wider range of business scenarios, making it easy to implement seamless interoperability across multiple systems. This change also guarantees the uniqueness of our data across databases and services, providing a solid foundation for potential horizontal scaling in the future, and demonstrating resilience and adaptability to a wide range of development challenges.

Please visit our GitHub repository [Yoyo.Abp](https://github.com/YoYoBoot/Yoyo.Abp) for more details and stay tuned for project updates. Don't forget to star and follow our repository to receive real-time updates!

We sincerely welcome any valuable comments and suggestions and look forward to hearing your feedback.
Join the YoYoBoot journey together and let's contribute to the development, further optimization and innovation of this project. 🚀🌟

## Features

- **Primary Key Type Flexibility**: You can flexibly choose `int`, `long`, `guid` or `string` type to define the primary key of an entity according to your project requirements.
- **Backwards Compatibility**: Our entity framework can be seamlessly integrated into existing ABP-based projects without the need for major refactoring.
- **Custom Entity Framework**: You can customize your own entity framework to support string-based primary keys.
- **Seamless Integration with Existing ABP Infrastructure**: Our Entity Framework can be seamlessly integrated with existing ABP infrastructure without introducing any conflicts or issues.
- **Enhanced Flexibility for Complex Deployment Scenarios**: Our Entity Framework provides more flexibility to cope with complex deployment scenarios and meet project requirements.

## Extended Resources - Examples

In addition to our Yoyo.Abp project, we are excited to share a template project [OpenYoYoBoot](https://github.com/YoYoBoot/OpenYoYoBoot) based on front-end and back-end separation with Yoyo.Abp, which is an out-of-the-box solution to help people quickly start and deployment of modern web applications. We highly recommend you to try this project to experience its well-designed and excellent performance, which perfectly combines the innovative features of the front-end with the powerful back-end architecture of Yoyo.Abp.

Thank you to the community for working together to make these projects a quality resource that is widely used. We look forward to your participation in taking the Yoyo.Abp and OpenYoYoBoot projects to the next level.

## Why this project?

We have developed too many projects based on the ABP framework, which is very good, but not perfect, especially in the case of entities Primary key types are important features for identifying unique records in databases and applications. In many cases, the default integer type (e.g. `int` or `long`) is used as the primary key. However, there are specific scenarios where using the `string` type as a primary key may provide additional benefits. The following are some of the possible advantages of switching an entity's primary key type from `int` to `string` and some of the potential disadvantages of using `int` as a primary key:

### Benefits of using `string` as a primary key

1. **Global uniqueness**: The `string` type can represent a GUID (globally unique identifier), which provides a simple global uniqueness solution for records across databases in a distributed system.
2. **Flexibility and Extensibility**: `string` primary keys can hold more than just numbers, and can be embedded in a specific format or schema, such as a date, classification code, or other business logic.
3. **Readability**: `string` type primary keys, especially those containing certain meaningful words or abbreviations, can improve record recognition and readability.
4. **Avoid self-incrementing performance issues**: In highly concurrent situations, self-incrementing `int` primary keys can be a performance bottleneck, especially in distributed databases. A `string` primary key (e.g. a pre-generated GUID) can alleviate this problem.
5. **Integration Friendly**: Using a `string` type primary key makes it easier to integrate with external systems that already use `string` as an identifier.

### Potential disadvantages of `int` as a primary key

1. **Limitations**: The `int` type provides a limited range of values and there is a risk of overflow in large systems or in situations where large data sets are required.
2. **No support for complex encodings**: The `int` type cannot contain any information other than numbers, so it does not support things like date encodings or other complex formats.
3. **Limitations in distributed systems**: In a distributed database environment, additional policies are required to ensure that `int` primary keys are globally unique, which can lead to complex implementations and performance losses.
4. **Self-augmentation issues**: Self-augmenting primary keys of type `int` may lead to locking and contention during concurrent inserts, affecting performance.
5. **Migration and Scaling Difficulties**: As business grows, there may be a need to migrate from `int` to a wider range of data types, which introduces additional workload and complexity.

In other words, choosing the appropriate primary key type needs to be based on application scenarios, performance requirements, maintainability, and future scalability. The enhanced ASP.NET Boilerplate Framework in the form of Yoyo.Abp provides additional freedom and adaptability in architectural choices by providing flexibility in entity primary key types to better adapt to the changing needs of software development.

## Project update notes

Every open source project is immensely worried about the subsequent lack of maintenance and updates, and we are no exception. In order to maintain the vitality and stability of our project, we are committed to regularly reviewing and merging updates and enhancements from the original source code repository to ensure that the latest features, security fixes, and performance improvements have been introduced into our project. This commitment is intended to provide our users and contributors with the most up-to-date, secure, and optimally performing experience and to ensure that discrepancies with the upstream source code repositories are minimized in a timely manner.

In order to better achieve this goal, the following are implementation details:

1. we will regularly monitor the original repository for updates through the appropriate channels.
2. we will perform the necessary review and testing work in 1-2 weeks when an update occurs in the original repository.
3. we will minimize localization specific changes to simplify the merging process with the original repository.
4. we will prioritize the merge operation if we find a critical update or security vulnerability fix.
5. We welcome the participation of community members, especially in helping to identify important upstream changes and testing the merge process.

We understand the importance of being transparent and responsive to the needs of the community and will endeavor to maintain good communication with the community and share update plans and progress. We also welcome feedback and suggestions from community members to help us better manage and maintain the program.

## Documentation

For extensive documentation on Yoyo.Abp, visit [documentation](https://github.com/yoyoboot/OpenYoYoBoot).

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yoyoboot/yoyo.abp&type=Date)](https://star-history.com/#yoyoboot/yoyo.abp&Date)

## Contributing

For those who'd like to contribute code, see our [Contribution Guide](CONTRIBUTING.md).

At the same time, please consider supporting Dify by sharing it on social media and at events and conferences.

### Contributions

<a href="https://github.com/yoyoboot/Yoyo.Abp/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=yoyoboot/Yoyo.Abp" />
</a>

## Acknowledgments

Thanks to the creators and contributors of [ASP.NET Boilerplate](https://github.com/aspnetboilerplate/aspnetboilerplate) for providing a solid infrastructure.

## License

This project is licensed under the MIT license - see the [LICENSE](LICENSE.md) file for details.
