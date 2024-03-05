
# Yoyo.Abp

<p align="center">
  <a href="./README.md">English</a> |
  <a href="./README_CN.md">简体中文</a> |
  <a href="./README_JA.md">日本語</a> |
  <a href="./README_ES.md">Español</a> |
  <a href="./README_KL.md">Klingon</a> |
  <a href="./README_FR.md">Français</a>
</p>

[![Build Status](https://github.com/aspnetboilerplate/aspnetboilerplate/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/aspnetboilerplate/aspnetboilerplate/actions/workflows/build-and-test.yml)
[![NuGet](https://img.shields.io/nuget/v/Abp.svg?style=flat-square)](https://www.nuget.org/packages/Abp)
[![MyGet (with prereleases)](https://img.shields.io/myget/abp-nightly/vpre/Abp.svg?style=flat-square)](https://aspnetboilerplate.com/Pages/Documents/Nightly-Builds)
[![NuGet Download](https://img.shields.io/nuget/dt/Abp.svg?style=flat-square)](https://www.nuget.org/packages/Abp)

欢迎光临 `Yoyo.Abp` 仓库！这个项目源自 [ASP.NET Boilerplate](https://github.com/aspnetboilerplate/aspnetboilerplate) 框架，并进行了改良，主要是将实体主键的默认类型由 `int` 更新为 `string`。我们兴奋地宣布 [Yoyo.Abp](https://github.com/YoYoBoot/Yoyo.Abp) 项目的推出，此项主旨更新不仅增强了系统的灵活性和扩展性，同时继承了原始 `ABP` 框架的强大功能与易用性。

这个项目不是冒然推广出来的 ，我们已经将它广泛应用于很多内部和商业项目中，因此你不是小白鼠,我们针对自有需求制定了这一调整，同时相信这一改动会使整个开发社区受益。

利用 `string` 型主键，我们的项目适配的业务场景更为广泛，轻松实施多系统间的无缝对接。这项改变也为我们的数据提供跨数据库和服务的独一无二性保障，为将来可能的水平扩展提供了坚实的基础，展现了应对各类开发挑战的弹性与韧性。

请访问我们的 GitHub 仓库[Yoyo.Abp](https://github.com/YoYoBoot/Yoyo.Abp)，那里有更多详细信息，也请继续关注我们的项目更新。别忘了给我们的仓库加星标和关注，以便实时接收最新进展！

我们诚挚地欢迎任何宝贵的意见和建议，并期待着听取您的反馈。一起加入YoYoBoot的旅程，让我们共同促进这个项目的发展，进一步优化和创新。🚀🌟

## 特点

- **主键类型灵活性**：您可以根据项目需求灵活地选择 `int`、`long`、`Guid` 或 `string` 类型来定义实体的主键。
- **向后兼容**：我们的实体框架可以无缝集成到已有的基于 ABP 的项目中，无需进行大规模重构。
- **自定义实体框架**：您可以自己定制实体框架，以支持基于字符串的主键。
- **与现有的ABP基础架构无缝集成**：我们的实体框架可以与已有的 ABP 基础架构无缝集成，不会引入任何冲突或问题。
- **增强了复杂部署方案的灵活性**：我们的实体框架提供了更多灵活性，可以应对复杂的部署方案，满足项目的需求。

## 扩展资源-示例

除了我们的 Yoyo.Abp 项目，我们还兴奋地分享了一个基于 前后端分离与 Yoyo.Abp 的模板项目 [OpenYoYoBoot](https://github.com/YoYoBoot/OpenYoYoBoot)，这是一个开箱即用的解决方案，可以帮助大家快速启动和部署现代 Web 应用程序。我们强烈推荐您尝试这个项目来体验其精心设计和优秀性能，它完美地结合了 前端的创新特性和 Yoyo.Abp 的强大后端架构。

感谢社区的朋友们的共同努力，让这些项目成为广泛使用的优质资源。我们期待您的参与，一起把 Yoyo.Abp 和 OpenYoYoBoot 项目推向更高的发展层次。

## 为什么会有这个项目？

我们基于ABP框架研发了太多的项目，它非常好，但是也不是完美的，尤其在实体主键类型是数据库和应用程序中标识唯一记录的重要特征。在许多情况下，默认的整数类型（如 `int` 或 `long`）被用作主键。但是，在一些特定场景下，使用 `string` 类型作为主键可能带来更多的好处。以下是切换实体主键类型从 `int` 到 `string` 可能产生的一些优势和 `int` 作为主键的一些潜在弊端：

### 使用 `string` 作为主键的好处

1. **全局唯一性**: `string` 类型可以表示GUID（全局唯一标识符），这为分布式系统中跨数据库的记录提供了一种简单的全局唯一性解决方案。
2. **灵活性和可扩展性**: `string` 主键可以容纳不仅仅是数字，还可以嵌入特定格式或模式，例如日期、分类代码或其他业务逻辑。
3. **可读性**: `string` 类型的主键，特别是那些包含某些有意义单词或缩写的，可以提高记录的识别度和可读性。
4. **避免自增性能问题**: 在高并发情况下，自增 `int` 主键可能会成为性能瓶颈，尤其是在分布式数据库中。`string` 主键（比如一个预先生成的GUID）可以缓解这个问题。
5. **集成友好**: 使用 `string` 类型的主键可以更容易地与那些原本就使用 `string` 作为标识符的外部系统集成。

### `int` 作为主键的潜在坏处

1. **限制性**: `int` 类型提供有限的数值范围，而在大型系统或需要大量数据集的情境下，可能存在溢出风险。
2. **不支持复杂编码**: `int` 类型无法包含除数字以外的任何信息，因此不支持诸如日期编码或其他复杂格式。
3. **分布式系统中的限制**: 在分布式数据库环境下，需要额外的策略来确保 `int` 主键全局唯一，这可能会导致复杂的实现和性能损失。
4. **自增问题**: `int` 类型的自增主键在并发插入时可能会导致锁定和争用，影响性能。
5. **迁移和扩展难度**: 随着业务的增长，可能会需要从 `int` 迁移至更大范围的数据类型，这会引入额外的工作量和复杂性。

换言之，选择适当的主键类型需要根据应用场景、性能要求、可维护性以及未来扩展性来综合考虑。Yoyo.Abp 形式的增强ASP.NET Boilerplate框架通过提供实体主键类型的灵活性，为架构选择提供了额外的自由度和适应能力，从而更好地适应多变的软件开发需求。

## 项目更新说明

每一个开源项目都无比担忧后续无人维护和更新，我们也不例外。为了保持项目的活力和稳定性，我们承诺将定期审查和合并来自原始源代码库的更新和改进，以确保在我们的项目中引入了最新的功能、安全性修复和性能改进。这一承诺旨在为我们的用户和贡献者提供最新、最安全、性能最优的使用体验，并确保及时减少与上游源代码库的差异。

为了更好地实现这一目标，以下是实施细节：

1. 我们会定期地通过合适的渠道关注原仓库的更新动态。
2. 当原仓库发生更新时，我们将在1-2周进行必要的审查和测试工作。
3. 我们将尽量减少本地化特定修改，以简化与原仓库的合并过程。
4. 如果发现有关键的更新或安全漏洞修复，我们会优先执行合并操作。
5. 我们欢迎社区成员的参与，特别是在帮助识别重要的上游变更和测试合并过程方面。

我们理解透明和响应社区需求的重要性，并将努力保持与社区的良好沟通，分享更新计划和进度。我们也欢迎社区成员的反馈和建议，以帮助我们更好地管理和维护这个项目。

## 文档

要了解关于 Yoyo.Abp 的详尽文档，请访问[文档](link-to-docs)。

## 贡献

我们欢迎各种形式的贡献。在提交拉取请求或开启问题之前，请先阅读我们的[贡献指南](link-to-contribution-guidelines)。

## 致谢

感谢 [ASP.NET Boilerplate](https://github.com/aspnetboilerplate/aspnetboilerplate) 的创建者和贡献者提供了坚实的基础架构。

## 许可证

本项目基于 MIT 许可证授权 - 详情请查看 [LICENSE](LICENSE.md) 文件。
