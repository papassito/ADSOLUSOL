```text
.github
│   └── workflows
│       └── ci.yml
docs
│   ├── architecture
│   │   ├── ADSOLUSOL.md
│   │   ├── AI-AD.md
│   │   ├── AI.md
│   │   ├── COMPONENTS.md
│   │   ├── MAP.md
│   │   ├── MOTOR.md
│   │   ├── ONION.md
│   │   ├── ORCHESTA.md
│   │   └── SITEMAP.md
│   ├── business
│   │   ├── CAMPAIGN.md
│   │   ├── MARKETING.md
│   │   └── SEO.md
│   ├── contracts
│   │   ├── CONTRACTS.md
│   │   └── MARKETING-API.md
│   ├── decisions
│   │   ├── ADR-001.md
│   │   └── DECISIONS.md
│   ├── evidence
│   │   └── EVIDENCE.md
│   ├── integration
│   │   └── MARKETING-BRAIN.md
│   ├── operations
│   │   └── VALIDATE.md
│   ├── phases
│   │   ├── PHASE-1.md
│   │   ├── PHASE-2.md
│   │   └── PHASE-3.md
│   ├── security
│   │   └── INTEGRITY.md
│   ├── ADSOLUSOL.md
│   ├── AI-AD.md
│   ├── AI.md
│   ├── CAMPAIGN.md
│   ├── COMPONENTS.md
│   ├── CONTRACTS.md
│   ├── DEPLOYMENT_PLESK_ADSOLUSOL.md
│   ├── EXPEDIENTE_CLINICO_MAESTRO.md
│   ├── HISTORIAL DE ACTIVIDADES.MD
│   ├── INTEGRITY.md
│   ├── LIBRARY.md
│   ├── MANIFEST.md
│   ├── MAP.md
│   ├── MARKETING-API.md
│   ├── MARKETING-BRAIN.md
│   ├── MARKETING.md
│   ├── MOTOR.md
│   ├── ONION.md
│   ├── ORCHESTA.md
│   ├── REQUIREMENTS.md
│   ├── ROADMAP.md
│   ├── SEO.md
│   ├── SITEMAP.md
│   ├── STRUCTURE.md
│   └── VALIDATE.md
scripts
│   ├── audit
│   │   ├── auditar_todo.ps1
│   │   ├── autopsia_integridad.ps1
│   │   ├── junta_medica.ps1
│   │   ├── radiologico_forense.ps1
│   │   └── smoke-test.ps1
│   └── maintenance
│       └── generate_docs.ps1
│   ├── audit_chismoso.ps1
│   ├── audit_ultra-mitotero.ps1
│   ├── check_structure.ps1
│   ├── chismoso.ps1
│   └── radiografia_codigo.ps1
src
│   ├── ADSOLUSOL.Application
│   │   ├── Enums
│   │   │   └── EventProcessingStatus.cs
│   │   ├── Features
│   │   ├── Interfaces
│   │   │   ├── IAppDbContext.cs
│   │   │   └── ITenantSettingsService.cs
│   │   ├── Services
│   │   │   ├── AdServingService.cs
│   │   │   ├── BudgetService.cs
│   │   │   ├── CampaignService.cs
│   │   │   ├── EventProcessingService.cs
│   │   │   ├── MetricsService.cs
│   │   │   └── TenantSettingsService.cs
│   │   └── ADSOLUSOL.Application.csproj
│   ├── ADSOLUSOL.Domain
│   │   ├── Entities
│   │   │   ├── AdEvent.cs
│   │   │   ├── Campaign.cs
│   │   │   ├── CampaignCreative.cs
│   │   │   ├── CampaignMetrics.cs
│   │   │   ├── CampaignPlacement.cs
│   │   │   ├── Creative.cs
│   │   │   ├── EventProcessingStatus.cs
│   │   │   ├── Placement.cs
│   │   │   └── TenantSetting.cs
│   │   ├── Enums
│   │   │   └── EventType.cs
│   │   ├── Exceptions
│   │   │   └── DomainException.cs
│   │   ├── Interfaces
│   │   │   ├── CoreSignatureVerifier.cs
│   │   │   ├── IAdEventRepository.cs
│   │   │   ├── IAssignmentRepository.cs
│   │   │   ├── ICampaignRepository.cs
│   │   │   ├── ICoreSignatureVerifier.cs
│   │   │   ├── ICreativeRepository.cs
│   │   │   ├── IMarketingBrainService.cs
│   │   │   ├── INodeRegistry.cs
│   │   │   ├── IPlacementRepository.cs
│   │   │   ├── ITenantSettingsRepository.cs
│   │   │   ├── IUnitOfWork.cs
│   │   │   └── TenantSettingsDto.cs
│   │   ├── ValueObjects
│   │   │   └── AdContent.cs
│   │   └── ADSOLUSOL.Domain.csproj
│   ├── ADSOLUSOL.Infrastructure
│   │   ├── ExternalServices
│   │   │   └── MarketingBrain
│   │   │       └── MarketingBrainClient.cs
│   │   ├── Persistence
│   │   │   └── AppDbContext.cs
│   │   ├── Repositories
│   │   │   ├── AdEventRepository.cs
│   │   │   ├── AssignmentRepository.cs
│   │   │   ├── CampaignRepository.cs
│   │   │   ├── CreativeRepository.cs
│   │   │   ├── PlacementRepository.cs
│   │   │   ├── TenantSettingsRepository.cs
│   │   │   └── UnitOfWork.cs
│   │   ├── Security
│   │   │   └── CoreSignatureVerifier.cs
│   │   └── ADSOLUSOL.Infrastructure.csproj
│   ├── ADSOLUSOL.Motor
│   │   ├── Engine
│   │   │   └── ExecutionEngine.cs
│   │   ├── Strategies
│   │   │   └── ExecutionStrategy.cs
│   │   └── ADSOLUSOL.Motor.csproj
│   ├── ADSOLUSOL.Orchestrator
│   │   ├── Coordinators
│   │   │   └── FlowCoordinator.cs
│   │   ├── Flows
│   │   │   └── IaOrchestrationFlow.cs
│   │   └── ADSOLUSOL.Orchestrator.csproj
│   ├── ADSOLUSOL.Presentation.Api
│   │   ├── Controllers
│   │   │   ├── AssignmentsController.cs
│   │   │   ├── CampaignsController.cs
│   │   │   ├── CreativesController.cs
│   │   │   ├── HealthController.cs
│   │   │   ├── MarketingController.cs
│   │   │   ├── PlacementsController.cs
│   │   │   ├── ServeController.cs
│   │   │   └── SettingsController.cs
│   │   ├── Health
│   │   │   └── DependencyHealthCheck.cs
│   │   ├── Middleware
│   │   │   ├── ExceptionMiddleware.cs
│   │   │   └── SignatureVerificationMiddleware.cs
│   │   ├── Security
│   │   │   ├── PanelAuthConfiguration.cs
│   │   │   └── PanelPasswordVerifier.cs
│   │   └── ADSOLUSOL.Presentation.Api.csproj
│   │   ├── App.razor
│   │   ├── appsettings.Development.json
│   │   ├── appsettings.json
│   │   ├── Dockerfile
│   │   ├── Home.razor
│   │   ├── index.html
│   │   ├── MainLayout.razor
│   │   └── Program.cs
│   ├── ADSOLUSOL.Presentation.Cmd
│   │   ├── Commands
│   │   │   ├── StartEngineCommand.cs
│   │   │   └── SyncCampaignsCommand.cs
│   │   └── ADSOLUSOL.Presentation.Cmd.csproj
│   │   ├── appsettings.json
│   │   └── Program.cs
│   ├── ADSOLUSOL.Presentation.Desktop
│   │   └── ADSOLUSOL.Presentation.Desktop.csproj
│   │   ├── App.cs
│   │   └── MauiProgram.cs
│   └── ADSOLUSOL.Presentation.Web
│       ├── src
│       │   ├── api.ts
│       │   ├── App.tsx
│       │   ├── main.tsx
│       │   ├── styles.css
│       │   ├── types.ts
│       │   └── vite-env.d.ts
│       ├── .env.example
│       ├── index.html
│       ├── package-lock.json
│       └── package.json
│       ├── tsconfig.json
│       ├── tsconfig.node.json
│       └── vite.config.ts
tests
│   ├── ADSOLUSOL.ArchitectureTests
│   │   └── ADSOLUSOL.ArchitectureTests.csproj
│   │   └── OnionArchitectureTests.cs
│   └── ADSOLUSOL.RegressionTests
│       ├── .env.example
│       └── ADSOLUSOL.RegressionTests.csproj
│       ├── PanelAuthenticationTests.cs
│       └── Program.cs
```
