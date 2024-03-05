# 为 ASP.NET Boilerplate 做贡献

<p align="center">
  <a href="./CONTRIBUTING.md">English</a> |
  <a href="./CONTRIBUTING_CN.md">简体中文</a>
  
</p>

ASP.NET Boilerplate 是一个[开源](https://github.com/aspnetboilerplate/aspnetboilerplate) 和社区驱动的项目。本指南旨在帮助任何人为该项目做出贡献。

## 代码贡献

您可以随时向 GitHub 代码库发送拉取请求。

- 从 GitHub 克隆 [ASP.NET Boilerplate 代码库](https://github.com/aspnetboilerplate/aspnetboilerplate/)。
- 进行所需的修改。
- 发送拉取请求。

在进行任何修改之前，请在 [GitHub issues page](https://github.com/aspnetboilerplate/aspnetboilerplate/issues) 上进行讨论。这样，其他开发人员就不会在同一问题上工作，您的 PR 被接受的机会也会更大。

### 错误修复与增强

您可能想修复一个已知的错误或进行一个计划中的增强。请参阅 GitHub 上的 [问题列表](https://github.com/aspnetboilerplate/aspnetboilerplate/issues)。

### 功能请求

如果您对框架或模块有功能方面的想法，请在 GitHub 上 [create an issue](https://github.com/aspnetboilerplate/aspnetboilerplate/issues/new) 或参与现有讨论。如果得到社区的支持，您就可以将其付诸实施。

### 文档贡献

您可能想改进 [文档](https://aspnetboilerplate.com/Pages/Documents)。如果是这样，请遵循以下步骤：

- 从 GitHub 克隆 [ABP 仓库](https://github.com/aspnetboilerplate/aspnetboilerplate/)。
- 文档位于 [/aspnetboilerplate/doc](https://github.com/aspnetboilerplate/aspnetboilerplate/tree/master/doc/WebSite) 文件夹中。
- 修改文档并发送拉取请求
- 如果要添加新文档，也需要将其添加到导航文档中。导航文档位于 [doc/WebSite/Navigation.md](https://github.com/aspnetboilerplate/aspnetboilerplate/blob/master/doc/WebSite/Navigation.md) 中。

## 资源本地化

ASP.NET Boilerplate 框架有一个 [本地化系统](https://aspnetboilerplate.com/Pages/Documents/Localization)。本地化资源位于 [Abp\Localization\Sources\AbpXmlSource](https://github.com/aspnetboilerplate/aspnetboilerplate/tree/dev/src/Abp/Localization/Sources/AbpXmlSource) 中。
您可以添加新的翻译或更新现有的翻译。
要添加缺失的翻译，请参阅 [this example pull request](https://github.com/aspnetboilerplate/aspnetboilerplate/pull/2471)

## 编写新模块

框架有预编译模块，你也可以添加新模块。[Abp.Dapper](https://github.com/aspnetboilerplate/aspnetboilerplate/tree/dev/src/Abp.Dapper)是一个贡献模块。你可以查看 Abp.Dapper 模块来创建自己的模块。

### 博客文章和教程

如果您想为 ASP.NET Boilerplate 编写教程或博文，请通知我们（通过创建 GitHub issue](<https://github.com/aspnetboilerplate/aspnetboilerplate/issues)），这样我们就可以在官方文档中添加您的教程/博文链接，并在官方> [Twitter 账户](https://twitter.com/aspboilerplate) 上公布。

## 错误报告

如果您想报告错误，请 [在 GitHub 仓库创建一个问题](https://github.com/aspnetboilerplate/aspnetboilerplate/issues/new)

## GitHub 问题

GitHub 问题用于错误报告、功能请求和其他有关框架的讨论。

如果您要创建错误/问题报告，请包含以下内容：

标记

- 您的 Abp 软件包版本
- 您的基础框架：.Net Framework 或 .Net Core。
- 异常消息和堆栈跟踪（如果有）。
- 重现问题所需的步骤。

```

仅限英语！

### 堆栈溢出

您可以使用 StackOverflow 解决有关使用框架、模板和示例的问题：

https://stackoverflow.com/questions/tagged/aspnetboilerplate

在问题中使用 `aspnetboilerplate` 标记。
