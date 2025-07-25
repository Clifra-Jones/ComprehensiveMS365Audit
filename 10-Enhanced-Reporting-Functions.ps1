# 10-Enhanced-Reporting-Functions.ps1
# Enhanced HTML reporting function updated for comprehensive M365 audit module
#

function Export-M365AuditHtmlReport {
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline
        )]
        [array]$AuditResults,
        
        [string]$OutputPath = ".\M365_Audit_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",
        [string]$OrganizationName = "Organization",
        [switch]$IncludeCharts,
        [bool]$IncludePIMAnalysis = $true,
        [bool]$IncludeComplianceGaps = $true
    )
    
    Write-Host "Generating enhanced HTML audit report..." -ForegroundColor Cyan
    
    if ($AuditResults.Count -eq 0) {
        Write-Warning "No audit results provided"
        return
    }
    
    # === USE HELPER FUNCTIONS FOR CALCULATIONS ===
    
    # Calculate comprehensive statistics using helper function
    $stats = Get-AuditStatistics -AuditResults $AuditResults
    
    # Get report metadata
    $metadata = Get-ReportMetadata -OrganizationName $OrganizationName -Stats $stats -AuditResults $AuditResults
    
    # Get report summary
    $summary = Get-ReportSummary -AuditResults $AuditResults -Stats $stats
    
    # Get service analysis
    $serviceAnalysis = Get-ServiceAnalysis -AuditResults $AuditResults -IncludeExchangeAnalysis
    
    # Get PIM analysis
    $pimAnalysis = Get-PIMAnalysis -AuditResults $AuditResults -IncludeDetailedAnalysis:$IncludePIMAnalysis
    
    # Get principal analysis
    $principalAnalysis = Get-PrincipalAnalysis -AuditResults $AuditResults
    
    # Get cross-service analysis
    $crossServiceAnalysis = Get-CrossServiceAnalysis -AuditResults $AuditResults
    
    # Get security alerts
    $securityAlerts = Get-SecurityAlerts -AuditResults $AuditResults -Stats $stats
    
    # Get recommendations
    $recommendations = Get-SecurityRecommendations -AuditResults $AuditResults -Stats $stats
    
    # Get compliance analysis if requested
    $complianceAnalysis = if ($IncludeComplianceGaps) {
        Get-ComplianceAnalysis -AuditResults $AuditResults -Stats $stats
    } else { $null }
    
    # === BUILD HTML USING HELPER FUNCTION DATA ===
    
    # Build enhanced HTML content
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>M365 Comprehensive Role Audit Report - $OrganizationName</title>
    <style>
        :root {
            --primary-color: #0078d4;
            --secondary-color: #106ebe;
            --success-color: #107c10;
            --warning-color: #ff8c00;
            --danger-color: #d13438;
            --info-color: #00bcf2;
            --dark-color: #323130;
            --light-color: #f3f2f1;
        }
        
        * { box-sizing: border-box; }
        
        body { 
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            line-height: 1.6;
        }
        
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            background: white; 
            padding: 40px; 
            border-radius: 12px; 
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
        }
        
        .header { 
            text-align: center; 
            margin-bottom: 40px; 
            padding-bottom: 30px; 
            border-bottom: 3px solid var(--primary-color);
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            color: white;
            margin: -40px -40px 40px -40px;
            padding: 40px;
            border-radius: 12px 12px 0 0;
        }
        
        .header h1 { 
            margin: 0; 
            font-size: 2.8em; 
            font-weight: 300;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        
        .header p { 
            margin: 15px 0 0 0; 
            font-size: 1.2em; 
            opacity: 0.9;
        }
        
        .metadata {
            background: var(--info-color);
            color: white;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .metadata-item {
            text-align: center;
        }
        
        .metadata-item strong {
            display: block;
            font-size: 0.9em;
            opacity: 0.8;
        }
        
        .metadata-item span {
            display: block;
            font-size: 1.1em;
            font-weight: bold;
        }
        
        .summary-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); 
            gap: 25px; 
            margin-bottom: 40px; 
        }
        
        .summary-card { 
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); 
            color: white; 
            padding: 30px; 
            border-radius: 12px; 
            text-align: center;
            position: relative;
            overflow: hidden;
            transition: transform 0.3s ease;
        }
        
        .summary-card:hover {
            transform: translateY(-5px);
        }
        
        .summary-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(45deg, transparent 30%, rgba(255,255,255,0.1) 50%, transparent 70%);
            transform: translateX(-100%);
            transition: transform 0.6s;
        }
        
        .summary-card:hover::before {
            transform: translateX(100%);
        }
        
        .summary-card h3 { 
            margin: 0 0 15px 0; 
            font-size: 1.3em; 
            font-weight: 400;
        }
        
        .summary-card .number { 
            font-size: 3em; 
            font-weight: bold; 
            margin: 15px 0;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        
        .summary-card .subtitle {
            font-size: 0.9em;
            opacity: 0.8;
        }
        
        .section { 
            margin-bottom: 50px; 
            position: relative;
        }
        
        .section h2 { 
            color: var(--primary-color); 
            border-bottom: 3px solid var(--primary-color); 
            padding-bottom: 15px; 
            font-size: 2em;
            font-weight: 300;
            margin-bottom: 25px;
            position: relative;
        }
        
        .section h2::after {
            content: '';
            position: absolute;
            bottom: -3px;
            left: 0;
            width: 60px;
            height: 3px;
            background: var(--warning-color);
        }
        
        .alert-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 25px 0;
        }
        
        .security-alerts { 
            background: linear-gradient(135deg, #fff3cd, #ffeaa7); 
            border: 1px solid var(--warning-color); 
            border-left: 5px solid var(--warning-color);
            border-radius: 8px; 
            padding: 25px; 
            margin: 25px 0; 
        }
        
        .security-alerts h3 {
            margin-top: 0;
            color: #856404;
            font-size: 1.2em;
        }
        
        .alert-item { 
            margin: 15px 0; 
            padding: 10px;
            border-radius: 5px;
            background: rgba(255,255,255,0.7);
        }
        
        .alert-warning { 
            color: #856404; 
            border-left: 4px solid var(--warning-color);
            padding-left: 15px;
        }
        
        .alert-critical { 
            color: #721c24; 
            font-weight: bold; 
            border-left: 4px solid var(--danger-color);
            padding-left: 15px;
            background: rgba(209, 52, 56, 0.1);
        }
        
        .alert-success {
            color: var(--success-color);
            border-left: 4px solid var(--success-color);
            padding-left: 15px;
            background: rgba(16, 124, 16, 0.1);
        }
        
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 25px 0; 
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 16px rgba(0,0,0,0.1);
        }
        
        th, td { 
            padding: 15px 12px; 
            text-align: left; 
            border-bottom: 1px solid #e1dfdd; 
        }
        
        th { 
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); 
            color: white; 
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.9em;
            letter-spacing: 0.5px;
        }
        
        tr:hover { 
            background-color: #f9f9f9; 
            transition: background-color 0.2s ease;
        }
        
        tr:nth-child(even) {
            background-color: #fafafa;
        }
        
        .service-badge {
            padding: 4px 12px;
            border-radius: 20px;
            color: white;
            font-size: 0.85em;
            font-weight: 600;
            text-align: center;
            display: inline-block;
            min-width: 120px;
        }
        
        .service-azure { background: linear-gradient(135deg, #0078d4, #106ebe); }
        .service-sharepoint { background: linear-gradient(135deg, #0b6623, #0e7629); }
        .service-exchange { background: linear-gradient(135deg, #d13438, #b02a37); }
        .service-teams { background: linear-gradient(135deg, #464775, #5b5d8a); }
        .service-purview { background: linear-gradient(135deg, #8b4789, #9e5a9c); }
        .service-intune { background: linear-gradient(135deg, #00bcf2, #0078d4); }
        .service-defender { background: linear-gradient(135deg, #ff8c00, #e67e22); }
        .service-powerplatform { background: linear-gradient(135deg, #742774, #8b4789); }
        
        .privilege-high { 
            background: linear-gradient(135deg, #ffebee, #ffcdd2); 
            border-left: 5px solid var(--danger-color); 
        }
        
        .privilege-medium { 
            background: linear-gradient(135deg, #fff3e0, #ffe0b2); 
            border-left: 5px solid var(--warning-color); 
        }
        
        .privilege-low { 
            background: linear-gradient(135deg, #e8f5e8, #c8e6c9); 
            border-left: 5px solid var(--success-color); 
        }
        
        .pim-analysis {
            background: linear-gradient(135deg, #e3f2fd, #bbdefb);
            border: 1px solid var(--info-color);
            border-radius: 8px;
            padding: 25px;
            margin: 25px 0;
        }
        
        .pim-analysis h3 {
            color: var(--info-color);
            margin-top: 0;
        }
        
        .progress-bar {
            background: #e0e0e0;
            border-radius: 10px;
            height: 20px;
            margin: 10px 0;
            overflow: hidden;
        }
        
        .progress-fill {
            height: 100%;
            border-radius: 10px;
            transition: width 0.5s ease;
        }
        
        .progress-pim { background: linear-gradient(135deg, var(--success-color), #16a085); }
        .progress-active { background: linear-gradient(135deg, var(--warning-color), #e67e22); }
        .progress-permanent { background: linear-gradient(135deg, var(--danger-color), #c0392b); }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .stat-item {
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            border-top: 4px solid var(--primary-color);
        }
        
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: var(--primary-color);
        }
        
        .stat-label {
            font-size: 0.9em;
            color: #666;
            margin-top: 5px;
        }
        
        .footer { 
            margin-top: 60px; 
            padding-top: 30px; 
            border-top: 2px solid #ddd; 
            text-align: center; 
            color: #666; 
            background: #f9f9f9;
            margin-left: -40px;
            margin-right: -40px;
            padding-left: 40px;
            padding-right: 40px;
            border-radius: 0 0 12px 12px;
        }
        
        .expandable {
            cursor: pointer;
            user-select: none;
        }
        
        .expandable:hover {
            background: #f0f0f0;
        }
        
        .expandable-content {
            display: none;
            padding: 15px;
            background: #f9f9f9;
            border-radius: 5px;
            margin-top: 10px;
        }
        
        .tag {
            display: inline-block;
            background: var(--primary-color);
            color: white;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.8em;
            margin: 2px;
        }
        
        .tag.pim { background: var(--success-color); }
        .tag.permanent { background: var(--warning-color); }
        .tag.disabled { background: var(--danger-color); }
        
        .scroll-to-top {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: var(--primary-color);
            color: white;
            border: none;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            cursor: pointer;
            box-shadow: 0 4px 16px rgba(0,0,0,0.2);
            transition: all 0.3s ease;
        }
        
        .scroll-to-top:hover {
            background: var(--secondary-color);
            transform: translateY(-2px);
        }

        /* Role Analysis Expandable Rows */
        .expandable-role-row {
            cursor: pointer;
            transition: background-color 0.2s ease;
        }
        
        .expandable-role-row:hover {
            background-color: #f0f8ff !important;
        }
        
        .expand-indicator {
            float: right;
            font-size: 0.8em;
            color: var(--primary-color);
            transition: transform 0.3s ease;
        }
        
        .expand-indicator.expanded {
            transform: rotate(90deg);
        }
        
        .role-assignments-row {
            background: #f9f9f9 !important;
        }
        
        .assignments-container {
            padding: 20px;
            background: #ffffff;
            border-radius: 8px;
            margin: 10px 0;
            box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .assignments-title {
            font-size: 1.1em;
            font-weight: bold;
            color: var(--primary-color);
            margin-bottom: 15px;
            padding-bottom: 8px;
            border-bottom: 2px solid var(--primary-color);
        }
        
        .assignments-horizontal {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            padding: 8px 0;
        }
        
        .assignment-chip {
            background: linear-gradient(135deg, #e3f2fd, #bbdefb);
            border: 1px solid var(--info-color);
            border-radius: 20px;
            padding: 8px 16px;
            font-size: 0.9em;
            font-weight: 500;
            color: #1565c0;
            white-space: nowrap;
            transition: all 0.2s ease;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .assignment-chip:hover {
            background: linear-gradient(135deg, #bbdefb, #90caf9);
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        
        .no-assignments {
            text-align: center;
            padding: 20px;
            color: #666;
            font-style: italic;
            background: #f9f9f9;
            border-radius: 8px;
        }

        /* User Analysis Expandable Rows */
        .expandable-user-row {
            cursor: pointer;
            transition: background-color 0.2s ease;
        }
        
        .expandable-user-row:hover {
            background-color: #f0f8ff !important;
        }
        
        .user-roles-row {
            background: #f9f9f9 !important;
        }
        
        .user-roles-cell {
            padding: 20px;
            background: #ffffff;
            border-radius: 8px;
            margin: 10px 0;
            box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .user-roles-title {
            font-size: 1.1em;
            font-weight: bold;
            color: var(--primary-color);
            margin-bottom: 15px;
            padding-bottom: 8px;
            border-bottom: 2px solid var(--primary-color);
        }
        
        /* Enhanced styles for compact user role display */
        .user-roles-container {
            display: flex;
            flex-direction: column;
            gap: 8px;
            padding: 10px 0;
        }

        .service-group-compact {
            margin-bottom: 12px;
        }

        .service-header-compact {
            font-weight: bold;
            color: var(--primary-color);
            font-size: 0.9em;
            margin-bottom: 4px;
            padding: 4px 0;
            border-bottom: 1px solid #e1dfdd;
        }

        .roles-list-compact {
            margin-left: 16px;
            list-style: none;
            padding: 0;
        }

        .role-item-compact {
            padding: 2px 0;
            font-size: 0.85em;
            color: #333;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .role-item-compact::before {
            content: "•";
            color: var(--primary-color);
            font-weight: bold;
            width: 8px;
        }

        .role-badge-mini {
            display: inline-block;
            background: var(--info-color);
            color: white;
            padding: 1px 6px;
            border-radius: 8px;
            font-size: 0.7em;
            font-weight: 500;
            margin-left: auto;
        }

        .role-badge-mini.pim-eligible {
            background: var(--success-color);
        }

        .role-badge-mini.pim-active {
            background: var(--warning-color);
        }

        .role-badge-mini.permanent {
            background: var(--primary-color);
        }

        /* Service header colors for compact view */
        .service-header-compact.azure { color: #0078d4; border-bottom-color: #0078d4; }
        .service-header-compact.sharepoint { color: #0b6623; border-bottom-color: #0b6623; }
        .service-header-compact.exchange { color: #d13438; border-bottom-color: #d13438; }
        .service-header-compact.teams { color: #464775; border-bottom-color: #464775; }
        .service-header-compact.purview { color: #8b4789; border-bottom-color: #8b4789; }
        .service-header-compact.intune { color: #00bcf2; border-bottom-color: #00bcf2; }
        .service-header-compact.defender { color: #ff8c00; border-bottom-color: #ff8c00; }
        .service-header-compact.powerplatform { color: #742774; border-bottom-color: #742774; }  
                
        /* Mobile Responsive */
        @media (max-width: 768px) {
            .container { padding: 20px; }
            .summary-grid { grid-template-columns: 1fr; }
            .header h1 { font-size: 2em; }
            table { font-size: 0.9em; }
            th, td { padding: 10px 8px; }
            
            .assignment-chip {
                font-size: 0.8em;
                padding: 6px 12px;
            }
            
            .assignments-horizontal {
                gap: 8px;
            }
            
            .service-group-header {
                font-size: 0.8em;
                padding: 10px 12px;
            }
            
            .role-item {
                font-size: 0.8em;
                padding: 6px 10px;
            }
        }

        .assignments-section {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        
        .assignments-legend {
            display: flex;
            gap: 20px;
            padding: 8px 12px;
            background: #f8f9fa;
            border-radius: 6px;
            border: 1px solid #e9ecef;
            font-size: 0.85em;
            justify-content: center;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 6px;
            font-weight: 500;
        }
        
        .legend-color {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            border: 1px solid rgba(0,0,0,0.2);
        }
        
        .legend-color.active {
            background: linear-gradient(135deg, #e3f2fd, #bbdefb);
        }
        
        .legend-color.eligible {
            background: linear-gradient(135deg, #fff3e0, #ffcc80);
        }
        
        .assignment-chip.active {
            background: linear-gradient(135deg, #e3f2fd, #bbdefb);
            border: 1px solid var(--info-color);
            color: #1565c0;
        }
        
        .assignment-chip.eligible {
            background: linear-gradient(135deg, #fff3e0, #ffcc80);
            border: 1px solid var(--warning-color);
            color: #ef6c00;
        }
        
        .assignment-chip.active:hover {
            background: linear-gradient(135deg, #bbdefb, #90caf9);
        }
        
        .assignment-chip.eligible:hover {
            background: linear-gradient(135deg, #ffcc80, #ffb74d);
        }
    </style>
    <script>
        function toggleSection(id) {
            const content = document.getElementById(id);
            if (content.style.display === 'none' || content.style.display === '') {
                content.style.display = 'block';
            } else {
                content.style.display = 'none';
            }
        }
        
        function scrollToTop() {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }

        function toggleRoleAssignments(roleId) {
            const assignmentsRow = document.getElementById('roleAssignments_' + roleId);
            const expandIndicator = event.currentTarget.querySelector('.expand-indicator');
            
            if (assignmentsRow.style.display === 'none' || assignmentsRow.style.display === '') {
                assignmentsRow.style.display = 'table-row';
                expandIndicator.textContent = '▼';
                expandIndicator.classList.add('expanded');
            } else {
                assignmentsRow.style.display = 'none';
                expandIndicator.textContent = '▶';
                expandIndicator.classList.remove('expanded');
            }
        }

        function toggleUserRoles(userId) {
            const rolesRow = document.getElementById('userRoles_' + userId);
            const expandIndicator = event.currentTarget.querySelector('.expand-indicator');
            
            if (rolesRow.style.display === 'none' || rolesRow.style.display === '') {
                rolesRow.style.display = 'table-row';
                expandIndicator.textContent = '▼';
                expandIndicator.classList.add('expanded');
            } else {
                rolesRow.style.display = 'none';
                expandIndicator.textContent = '▶';
                expandIndicator.classList.remove('expanded');
            }
        }
        
        document.addEventListener('DOMContentLoaded', function() {
            window.addEventListener('scroll', function() {
                const scrollBtn = document.querySelector('.scroll-to-top');
                if (window.pageYOffset > 300) {
                    scrollBtn.style.display = 'block';
                } else {
                    scrollBtn.style.display = 'none';
                }
            });
        });
    </script>
</head>
<body>
    <button class="scroll-to-top" onclick="scrollToTop()" style="display: none;">↑</button>
    
    <div class="container">
        <div class="header">
            <h1>Microsoft 365 Comprehensive Role Audit</h1>
            <p>$OrganizationName | Generated on $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm")</p>
        </div>
        
        <div class="metadata">
            <div class="metadata-item">
                <strong>Audit Scope</strong>
                <span>$($metadata.servicesAudited) Services</span>
            </div>
            <div class="metadata-item">
                <strong>Authentication</strong>
                <span>$(if($metadata.certificateAuthUsed) { "Certificate-Based" } else { "Mixed" })</span>
            </div>
            <div class="metadata-item">
                <strong>PIM Analysis</strong>
                <span>$(if($metadata.pimEnabled) { "Included" } else { "N/A" })</span>
            </div>
            <div class="metadata-item">
                <strong>Hybrid Environment</strong>
                <span>$(if($metadata.hybridEnvironmentDetected) { "Detected" } else { "Cloud-Only" })</span>
            </div>
        </div>

        <div class="summary-grid">
            <div class="summary-card">
                <h3>Total Role Assignments</h3>
                <div class="number">$($metadata.totalAssignments)</div>
                <div class="subtitle">Across all services</div>
            </div>
            <div class="summary-card">
                <h3>Unique Users</h3>
                <div class="number">$($metadata.uniqueUsers)</div>
                <div class="subtitle">With role assignments</div>
            </div>
            <div class="summary-card">
                <h3>Services Audited</h3>
                <div class="number">$($metadata.servicesAudited)</div>
                <div class="subtitle">Microsoft 365 services</div>
            </div>
            <div class="summary-card">
                <h3>Global Administrators</h3>
                <div class="number">$($stats.globalAdmins.Count)</div>
                <div class="subtitle">Highest privilege level</div>
            </div>
"@

    # Add PIM summary cards if PIM data exists
    if ($pimAnalysis.enabled) {
        $html += @"
            <div class="summary-card">
                <h3>PIM Eligible</h3>
                <div class="number">$($pimAnalysis.totalEligible)</div>
                <div class="subtitle">Require activation</div>
            </div>
            <div class="summary-card">
                <h3>PIM Active</h3>
                <div class="number">$($pimAnalysis.totalActive)</div>
                <div class="subtitle">Currently activated</div>
            </div>
"@
    }

    $html += @"
        </div>

        <div class="section">
            <h2>🔐 Security Analysis</h2>
"@

    # Enhanced security alerts using helper function data
    $html += '<div class="alert-grid">'

    # Critical alerts
    if ($securityAlerts.critical.Count -gt 0) {
        $html += @"
            <div class="security-alerts" style="background: linear-gradient(135deg, #ffebee, #ffcdd2); border-color: var(--danger-color);">
                <h3 style="color: var(--danger-color);">Critical Issues</h3>
"@
        foreach ($alert in $securityAlerts.critical) {
            $html += "<div class='alert-item alert-critical'>⚠️ $alert</div>"
        }
        $html += "</div>"
    }

    # High priority alerts
    if ($securityAlerts.high.Count -gt 0) {
        $html += @"
            <div class="security-alerts">
                <h3>High Priority Issues</h3>
"@
        foreach ($alert in $securityAlerts.high) {
            $html += "<div class='alert-item alert-warning'>⚠️ $alert</div>"
        }
        $html += "</div>"
    }

    # Medium priority alerts
    if ($securityAlerts.medium.Count -gt 0) {
        $html += @"
            <div class="security-alerts">
                <h3>Medium Priority Issues</h3>
"@
        foreach ($alert in $securityAlerts.medium) {
            $html += "<div class='alert-item alert-warning'>⚠️ $alert</div>"
        }
        $html += "</div>"
    }

    # Low priority alerts
    if ($securityAlerts.low.Count -gt 0) {
        $html += @"
            <div class="security-alerts" style="background: linear-gradient(135deg, #e8f5e8, #c8e6c9); border-color: var(--success-color);">
                <h3 style="color: var(--success-color);">Low Priority Items</h3>
"@
        foreach ($alert in $securityAlerts.low) {
            $html += "<div class='alert-item alert-success'>ℹ️ $alert</div>"
        }
        $html += "</div>"
    }

    $html += "</div>" # Close alert-grid

    # Add PIM Analysis section if applicable
    if ($IncludePIMAnalysis -and $pimAnalysis.enabled) {
        $html += @"
        </div>

        <div class="section">
            <h2>🔑 Privileged Identity Management Analysis</h2>
            <div class="pim-analysis">
                <h3>Assignment Type Distribution</h3>
                <div class="stats-grid">
                    <div class="stat-item">
                        <div class="stat-number" style="color: var(--success-color);">$($pimAnalysis.totalEligible)</div>
                        <div class="stat-label">PIM Eligible</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number" style="color: var(--info-color);">$($pimAnalysis.totalActive)</div>
                        <div class="stat-label">PIM Active</div>
                    </div>
                </div>
            </div>
"@
    }

    $html += @"
        </div>

        <div class="section">
            <h2>📊 Service Distribution</h2>
            <table>
                <tr><th>Service</th><th>Assignments</th><th>Percentage</th></tr>
"@

    # Service breakdown using helper function data
    foreach ($service in $summary.serviceBreakdown) {
        $serviceClass = switch ($service.service) {
            "Azure AD/Entra ID" { "service-azure" }
            "SharePoint Online" { "service-sharepoint" }
            "Exchange Online" { "service-exchange" }
            "Microsoft Teams" { "service-teams" }
            "Microsoft Purview" { "service-purview" }
            "Microsoft Intune" { "service-intune" }
            "Microsoft Defender" { "service-defender" }
            "Power Platform" { "service-powerplatform" }
            default { "service-azure" }
        }
        
        $html += @"
<tr>
    <td><span class='service-badge $serviceClass'>$($service.service)</span></td>
    <td><strong>$($service.count)</strong></td>
    <td>$($service.percentage)%</td>
</tr>
"@
    }

    $html += @"
            </table>
        </div>

        <div class="section">
            <h2>👑 High-Privilege Role Analysis</h2>
            <table>
                <tr><th>Role Name</th><th>Users Assigned</th><th>Risk Level</th><th>Services</th></tr>
"@

        # Top roles using helper function data
    foreach ($role in $summary.topRoles) {
        $riskClass = switch ($role.riskLevel) {
            "CRITICAL" { "privilege-high" }
            "HIGH" { "privilege-medium" }
            "MEDIUM" { "privilege-medium" }
            default { "privilege-low" }
        }
        
        $servicesDisplay = ($role.services | Select-Object -First 3) -join ", "
        if ($role.services.Count -gt 3) { $servicesDisplay += "..." }
        
        # Get role users using the helper function
        $roleUsers = Get-RoleUsers -AuditResults $AuditResults -RoleName $role.roleName
        $roleId = ($role.roleName -replace '[^a-zA-Z0-9]', '')
        
# Build simple assignments list with PIM differentiation
        $assignmentsGrid = ""
        if ($roleUsers.Count -gt 0) {
            # Count different assignment types for legend
            $activeCount = ($roleUsers | Where-Object { $_.assignmentType -notlike "*Eligible*" }).Count
            $eligibleCount = ($roleUsers | Where-Object { $_.assignmentType -like "*Eligible*" }).Count
            
            $assignmentsGrid = "<div class='assignments-section'>"
            $assignmentsGrid += "<div class='assignments-horizontal'>"
            
            foreach ($user in $roleUsers) {
                $chipClass = if ($user.assignmentType -like "*Eligible*") { "assignment-chip eligible" } else { "assignment-chip active" }
                $assignmentsGrid += "<div class='$chipClass'>$($user.displayName)</div>"
            }
            $assignmentsGrid += "</div>"
            
            # Add legend at the bottom if there are both types
            if ($activeCount -gt 0 -and $eligibleCount -gt 0) {
                $assignmentsGrid += "<div class='assignments-legend'>"
                $assignmentsGrid += "<span class='legend-item'><span class='legend-color active'></span> Active Assignments ($activeCount)</span>"
                $assignmentsGrid += "<span class='legend-item'><span class='legend-color eligible'></span> PIM Eligible ($eligibleCount)</span>"
                $assignmentsGrid += "</div>"
            } elseif ($eligibleCount -gt 0) {
                $assignmentsGrid += "<div class='assignments-legend'>"
                $assignmentsGrid += "<span class='legend-item'><span class='legend-color eligible'></span> PIM Eligible ($eligibleCount)</span>"
                $assignmentsGrid += "</div>"
            } elseif ($activeCount -gt 0) {
                $assignmentsGrid += "<div class='assignments-legend'>"
                $assignmentsGrid += "<span class='legend-item'><span class='legend-color active'></span> Active Assignments ($activeCount)</span>"
                $assignmentsGrid += "</div>"
            }
            
            $assignmentsGrid += "</div>"
        } else {
            $assignmentsGrid = "<div class='no-assignments'>No assignments found</div>"
        }
        
        $html += @"
<tr class='$riskClass expandable-role-row' onclick="toggleRoleAssignments('$roleId')">
    <td><strong>$($role.roleName)</strong> <span class='expand-indicator'>▶</span></td>
    <td>$($role.assignmentCount)</td>
    <td><span class='tag $(if($role.riskLevel -eq "CRITICAL") {"disabled"} elseif($role.riskLevel -eq "HIGH") {"permanent"} else {"pim"})'>$($role.riskLevel)</span></td>
    <td><small>$servicesDisplay</small></td>
</tr>
<tr id="roleAssignments_$roleId" class="role-assignments-row" style="display: none;">
    <td colspan="4" class="assignments-container">
        <div class="assignments-title">Role Assignments for $($role.roleName)</div>
        $assignmentsGrid
    </td>
</tr>
"@
    }

    $html += @"
            </table>
        </div>

        <div class="section">
            <h2>👥 User Analysis</h2>
            <table>
                <tr><th>User</th><th>Role Count</th><th>Status</th><th>Services</th></tr>
"@

    # User analysis using helper function data
    foreach ($user in $summary.usersWithMostRoles) {
        $statusColor = if ($user.isEnabled -eq $false) { "style='color: var(--danger-color); font-weight: bold;'" } else { "" }
        $status = if ($user.isEnabled -eq $false) { "DISABLED" } else { "Active" }
        
        $servicesDisplay = ($user.services | Select-Object -First 3) -join ", "
        if ($user.services.Count -gt 3) { $servicesDisplay += " +$($user.services.Count - 3) more" }
        
        # Get user roles grouped by service using helper function
        $userRoles = Get-UserRoles -AuditResults $AuditResults -UserPrincipalName $user.userPrincipalName
        $userId = ($user.userPrincipalName -replace '[^a-zA-Z0-9]', '')
        
                $serviceGroupedRoles = ""
        if ($userRoles.Count -gt 0) {
            $rolesByService = $userRoles | Group-Object Service | Sort-Object Name
            $serviceGroupedRoles = "<div class='user-roles-container'>"
            
            foreach ($serviceGroup in $rolesByService) {
                # Determine service class for color coding
                $serviceClass = switch ($serviceGroup.Name) {
                    "Azure AD/Entra ID" { "azure" }
                    "SharePoint Online" { "sharepoint" }
                    "Exchange Online" { "exchange" }
                    "Microsoft Teams" { "teams" }
                    "Microsoft Purview" { "purview" }
                    "Microsoft Intune" { "intune" }
                    "Microsoft Defender" { "defender" }
                    "Power Platform" { "powerplatform" }
                    default { "azure" }
                }
                
                $serviceGroupedRoles += "<div class='service-group-compact'>"
                $serviceGroupedRoles += "<div class='service-header-compact $serviceClass'>$($serviceGroup.Name)</div>"
                $serviceGroupedRoles += "<ul class='roles-list-compact'>"
                
                foreach ($role in $serviceGroup.Group | Sort-Object RoleName) {
                    # Determine assignment type badge
                    $badgeClass = "permanent"
                    $badgeText = "Active"
                    
                    if ($role.AssignmentType -like "*Eligible*") {
                        $badgeClass = "pim-eligible"
                        $badgeText = "PIM Eligible"
                    } elseif ($role.AssignmentType -like "*PIM*") {
                        $badgeClass = "pim-active"
                        $badgeText = "PIM Active"
                    }
                    
                    $serviceGroupedRoles += "<li class='role-item-compact'>"
                    $serviceGroupedRoles += "<span>$($role.RoleName)</span>"
                    $serviceGroupedRoles += "<span class='role-badge-mini $badgeClass'>$badgeText</span>"
                    $serviceGroupedRoles += "</li>"
                }
                
                $serviceGroupedRoles += "</ul></div>"
            }
                $serviceGroupedRoles += "</div>"
        } else {
            $serviceGroupedRoles = "<div class='no-roles'>No roles found</div>"
        }
            
        $html += @"
<tr class='expandable-user-row' onclick="toggleUserRoles('$userId')">
    <td $statusColor><strong>$($user.displayName)</strong><br><small style='color: #666;'>$($user.userPrincipalName)</small> <span class='expand-indicator'>▶</span></td>
    <td><strong>$($user.roleCount)</strong></td>
    <td><span class='tag $(if($status -eq "DISABLED") {"disabled"} else {"pim"})' $statusColor>$status</span></td>
    <td><small>$servicesDisplay</small></td>
</tr>
<tr id="userRoles_$userId" class="user-roles-row" style="display: none;">
    <td colspan="4" class="user-roles-cell">
        <div class="user-roles-title">Roles assigned to: $($user.displayName)</div>
        $serviceGroupedRoles
    </td>
</tr>
"@
    }

    $html += @"
            </table>
        </div>

        <div class="section">
            <h2>🔍 Principal Type Analysis</h2>
            <div class="stats-grid">
                <div class="stat-item">
                    <div class="stat-number">$($principalAnalysis.users)</div>
                    <div class="stat-label">Users</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">$($principalAnalysis.groups)</div>
                    <div class="stat-label">Groups</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">$($principalAnalysis.servicePrincipals)</div>
                    <div class="stat-label">Service Principals</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">$($principalAnalysis.onPremisesSyncedUsers)</div>
                    <div class="stat-label">On-Premises Synced</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>🌐 Cross-Service Analysis</h2>
            <div class="stats-grid">
                <div class="stat-item">
                    <div class="stat-number">$($crossServiceAnalysis.usersWithMultipleServices)</div>
                    <div class="stat-label">Multi-Service Users</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">$($crossServiceAnalysis.exchangeAzureADCombinations)</div>
                    <div class="stat-label">Exchange + Azure AD</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">$($crossServiceAnalysis.exchangePurviewCombinations)</div>
                    <div class="stat-label">Exchange + Purview</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>📋 Service-Specific Insights</h2>
            <div class="alert-grid">
"@

# Service-specific insights using helper function data
    foreach ($serviceName in $serviceAnalysis.Keys) {
        $serviceData = $serviceAnalysis[$serviceName]
        
        # Get PIM counts for this service using helper function
        $pimCounts = Get-ServicePIMCounts -AuditResults $AuditResults -ServiceName $serviceName
        
        # Determine service-specific color and icon
        $serviceInfo = switch ($serviceName) {
            "Azure AD/Entra ID" { @{ color = "#0078d4"; icon = "🔷" } }
            "SharePoint Online" { @{ color = "#0b6623"; icon = "📊" } }
            "Exchange Online" { @{ color = "#d13438"; icon = "📧" } }
            "Microsoft Teams" { @{ color = "#464775"; icon = "👥" } }
            "Microsoft Purview" { @{ color = "#8b4789"; icon = "🛡️" } }
            "Microsoft Intune" { @{ color = "#00bcf2"; icon = "📱" } }
            "Microsoft Defender" { @{ color = "#ff8c00"; icon = "🔐" } }
            "Power Platform" { @{ color = "#742774"; icon = "⚡" } }
            default { @{ color = "#0078d4"; icon = "🔒" } }
        }
        
        $html += @"
                <div class="security-alerts" style="border-color: $($serviceInfo.color);">
                    <h3 style="color: $($serviceInfo.color);">$($serviceInfo.icon) $serviceName Analysis</h3>
                    <div class="alert-item">📊 Total Assignments: $($serviceData.totalAssignments)</div>
                    <div class="alert-item">👥 Unique Users: $($serviceData.uniqueUsers)</div>
                    <div class="alert-item">🔴 PIM Active: $($pimCounts.pimActive)</div>
                    <div class="alert-item">🟢 PIM Eligible: $($pimCounts.pimEligible)</div>
                    <div class="alert-item">🎯 Top Role: $($serviceData.topRole)</div>
"@
        
        # Add service-specific analysis if available
        if ($serviceData.ContainsKey('exchangeAnalysis')) {
            $exData = $serviceData.exchangeAnalysis
            $html += @"
                    <div class="alert-item">🔄 On-Premises Synced: $($exData.onPremisesSyncedUsers)</div>
                    <div class="alert-item">👥 Group Assignments: $($exData.groupAssignments)</div>
                    <div class="alert-item">🏢 Hybrid Environment: $(if($exData.hybridEnvironment) {"Yes"} else {"No"})</div>
"@
        }
        
        if ($serviceData.ContainsKey('intuneAnalysis')) {
            $intData = $serviceData.intuneAnalysis
            $html += @"
                    <div class="alert-item">🔧 RBAC Assignments: $($intData.rbacAssignments)</div>
                    <div class="alert-item">🔷 Azure AD Assignments: $($intData.azureADAssignments)</div>
                    <div class="alert-item">⚙️ Service Administrators: $($intData.serviceAdministrators)</div>
"@
        }
        
        if ($serviceData.ContainsKey('sharePointAnalysis')) {
            $spData = $serviceData.sharePointAnalysis
            $html += @"
                    <div class="alert-item">🌐 Unique Sites: $($spData.uniqueSites)</div>
                    <div class="alert-item">👑 Site Collection Admins: $($spData.siteCollectionAdmins)</div>
                    <div class="alert-item">📱 App Catalog Admins: $($spData.appCatalogAdmins)</div>
"@
        }
        
        $html += "</div>"
    }

    $html += @"
            </div>
        </div>

        <div class="section">
            <h2>📋 Detailed Assignment Summary</h2>
            <div class="expandable" onclick="toggleSection('detailedAssignments')">
                <h3 style="cursor: pointer; color: var(--primary-color);">▶ View Detailed Assignments (Click to expand)</h3>
            </div>
            <div id="detailedAssignments" class="expandable-content">
                <p><em>Showing first 150 assignments. Export to CSV for complete data.</em></p>
                <table>
                    <tr>
                        <th>Service</th>
                        <th>User</th>
                        <th>Role</th>
                        <th>Assignment Type</th>
                        <th>Status</th>
                        <th>Scope</th>
                    </tr>
"@

    # Show first 150 assignments using formatted assignments from helper function
    $formattedAssignments = Get-FormattedAssignments -AuditResults $AuditResults
    $displayResults = $formattedAssignments | Select-Object -First 150
    
    foreach ($assignment in $displayResults) {
        $serviceClass = switch ($assignment.service) {
            "Azure AD/Entra ID" { "service-azure" }
            "SharePoint Online" { "service-sharepoint" }
            "Exchange Online" { "service-exchange" }
            "Microsoft Teams" { "service-teams" }
            "Microsoft Purview" { "service-purview" }
            "Microsoft Intune" { "service-intune" }
            "Microsoft Defender" { "service-defender" }
            "Power Platform" { "service-powerplatform" }
            default { "service-azure" }
        }
        
        $userDisplay = if ($assignment.userPrincipalName -and $assignment.userPrincipalName -ne "Unknown") { 
            $assignment.userPrincipalName 
        } else { 
            $assignment.displayName 
        }
        
        $scopeDisplay = if ($assignment.scope -and $assignment.scope.Length -gt 50) { 
            $assignment.scope.Substring(0, 47) + "..." 
        } else { 
            $assignment.scope 
        }
        
        # User status
        $userStatus = if ($assignment.userEnabled -eq $false) {
            "<span class='tag disabled'>DISABLED</span>"
        } else {
            "<span class='tag pim'>ACTIVE</span>"
        }
        
        # Assignment type styling
        $assignmentTypeDisplay = if ($assignment.assignmentType -like "*Eligible*") {
            "<span class='tag pim'>$($assignment.assignmentType)</span>"
        } elseif ($assignment.assignmentType -like "*PIM*") {
            "<span class='tag'>$($assignment.assignmentType)</span>"
        } else {
            "<span class='tag permanent'>$($assignment.assignmentType)</span>"
        }
        
        $html += @"
<tr>
    <td><span class='service-badge $serviceClass' style='font-size: 0.7em; padding: 2px 8px;'>$($assignment.service)</span></td>
    <td><small>$userDisplay</small></td>
    <td><strong>$($assignment.roleName)</strong></td>
    <td>$assignmentTypeDisplay</td>
    <td>$userStatus</td>
    <td><small>$scopeDisplay</small></td>
</tr>
"@
    }

    if ($AuditResults.Count -gt 150) {
        $html += @"
<tr>
    <td colspan='6' style='text-align: center; font-style: italic; color: #666; background: #f9f9f9;'>
        ... and $($AuditResults.Count - 150) more assignments<br>
        <small>Export to CSV for complete data set</small>
    </td>
</tr>
"@
    }

    $html += @"
                </table>
            </div>
        </div>

        <div class="section">
            <h2>💡 Security Recommendations</h2>
            <div class="security-alerts" style="background: linear-gradient(135deg, #e8f5e8, #c8e6c9); border-color: var(--success-color);">
                <h3 style="color: var(--success-color);">Actionable Recommendations</h3>
"@

    # Generate recommendations using helper function
    foreach ($category in @('immediate', 'shortTerm', 'longTerm')) {
        if ($recommendations.ContainsKey($category) -and $recommendations[$category].Count -gt 0) {
            $priorityLabel = switch ($category) {
                'immediate' { 'Immediate Action Required' }
                'shortTerm' { 'Short-term Improvements' }
                'longTerm' { 'Long-term Strategy' }
            }
            
            $html += "<div class='alert-item'><strong>${priorityLabel}:</strong></div>"
            foreach ($rec in $recommendations[$category]) {
                $html += "<div class='alert-item'>• $rec</div>"
            }
        }
    }

    $html += @"
            </div>
        </div>

        <div class="section">
            <h2>📈 Enhanced Reporting Options</h2>
            <div class="pim-analysis">
                <h3>Additional Analysis Available</h3>
                <div class="stats-grid">
                    <div class="stat-item">
                        <div class="stat-label"><strong>PowerShell Commands</strong></div>
                        <small>Export-M365AuditJsonReport</small><br>
                        <small>Get-M365RoleAnalysis</small><br>
                        <small>Get-M365ComplianceGaps</small>
                    </div>
                    <div class="stat-item">
                        <div class="stat-label"><strong>Automation</strong></div>
                        <small>New-M365AuditScheduledTask</small><br>
                        <small>Certificate-based auth</small><br>
                        <small>Unattended execution</small>
                    </div>
                    <div class="stat-item">
                        <div class="stat-label"><strong>Integration</strong></div>
                        <small>JSON export for SIEM</small><br>
                        <small>CSV for spreadsheet analysis</small><br>
                        <small>API-ready data format</small>
                    </div>
                </div>
            </div>
        </div>
"@

    # Add compliance analysis if requested and available
    if ($IncludeComplianceGaps -and $complianceAnalysis) {
        $html += @"
        <div class="section">
            <h2>⚖️ Compliance Analysis</h2>
            <div class="stats-grid">
                <div class="stat-item">
                    <div class="stat-number" style="color: $(if($complianceAnalysis.privilegedAccessCompliance.globalAdminLimit.compliant) {'var(--success-color)'} else {'var(--danger-color)'});">
                        $(if($complianceAnalysis.privilegedAccessCompliance.globalAdminLimit.compliant) {'✓'} else {'✗'})
                    </div>
                    <div class="stat-label">Global Admin Compliance</div>
                    <small>$($complianceAnalysis.privilegedAccessCompliance.globalAdminLimit.current)/$($complianceAnalysis.privilegedAccessCompliance.globalAdminLimit.recommended) admins</small>
                </div>
                <div class="stat-item">
                    <div class="stat-number" style="color: $(if($complianceAnalysis.privilegedAccessCompliance.pimImplementation.compliant) {'var(--success-color)'} else {'var(--warning-color)'});">
                        $(if($complianceAnalysis.privilegedAccessCompliance.pimImplementation.compliant) {'✓'} else {'△'})
                    </div>
                    <div class="stat-label">PIM Implementation</div>
                    <small>$($complianceAnalysis.privilegedAccessCompliance.pimImplementation.eligibleCount) eligible assignments</small>
                </div>
                <div class="stat-item">
                    <div class="stat-number" style="color: $(if($complianceAnalysis.privilegedAccessCompliance.disabledAccountCleanup.compliant) {'var(--success-color)'} else {'var(--danger-color)'});">
                        $(if($complianceAnalysis.privilegedAccessCompliance.disabledAccountCleanup.compliant) {'✓'} else {'✗'})
                    </div>
                    <div class="stat-label">Account Cleanup</div>
                    <small>$($complianceAnalysis.privilegedAccessCompliance.disabledAccountCleanup.violationCount) violations</small>
                </div>
                <!-- <div class="stat-item">
                    <div class="stat-number" style="color: $(if($complianceAnalysis.authenticationCompliance.certificateBasedAuth.compliant) {'var(--success-color)'} else {'var(--warning-color)'});">
                        $($complianceAnalysis.authenticationCompliance.certificateBasedAuth.percentage)%
                    </div>
                    <div class="stat-label">Certificate Auth Usage</div>
                    <small>Secure authentication percentage</small>
                </div> -->
            </div>
        </div>
"@
    }

    $html += @"
        <div class="footer">
            <p><strong>Microsoft 365 Comprehensive Role Audit Report</strong></p>
            <p>Generated by Enhanced PowerShell Audit Module v2.0</p>
            <p>Authentication: Certificate-based (Secure) | Report Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
            <p>For complete data analysis, export results to CSV format</p>
            <p style="margin-top: 15px; font-size: 0.9em; color: #888;">
                This report provides comprehensive role assignment analysis across Microsoft 365 services.<br>
                Regular auditing helps maintain security posture and compliance requirements.
            </p>
        </div>
    </div>
</body>
</html>
"@

    try {
        $html | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "✓ Enhanced HTML report generated using helper functions: $OutputPath" -ForegroundColor Green
        
        # Show report summary using helper function
        Show-ReportSummary -Report @{
            metadata = $metadata
            securityAlerts = $securityAlerts
        } -OutputPath $OutputPath
        
        # Open report if on Windows
        if ($IsWindows -ne $false -and (Test-Path $OutputPath)) {
            $openReport = Read-Host "Open enhanced report in browser? (y/N)"
            if ($openReport -eq "y" -or $openReport -eq "Y") {
                Start-Process $OutputPath
            }
        }
        
        return $OutputPath
    }
    catch {
        Write-Error "Failed to generate enhanced HTML report: $($_.Exception.Message)"
        return $null
    }
}


function Export-M365AuditJsonReport {
    param(
        [Parameter(Mandatory = $true)]
        [array]$AuditResults,
        
        [string]$OutputPath = ".\M365_Audit_Data_$(Get-Date -Format 'yyyyMMdd_HHmmss').json",
        [string]$OrganizationName = "Organization",
        [switch]$IncludeComplianceAnalysis,
        [switch]$IncludePIMAnalysis,
        [switch]$IncludeExchangeAnalysis
    )
    
    Write-Host "Generating comprehensive JSON audit report..." -ForegroundColor Cyan
    
    if ($AuditResults.Count -eq 0) {
        Write-Warning "No audit results provided"
        return
    }
    
    # Calculate basic statistics
    $stats = Get-AuditStatistics -AuditResults $AuditResults
    
    # Build comprehensive JSON report
    $report = @{
        metadata = Get-ReportMetadata -OrganizationName $OrganizationName -Stats $stats -AuditResults $AuditResults
        summary = Get-ReportSummary -AuditResults $AuditResults -Stats $stats
        serviceAnalysis = Get-ServiceAnalysis -AuditResults $AuditResults -IncludeExchangeAnalysis:$IncludeExchangeAnalysis
        pimAnalysis = Get-PIMAnalysis -AuditResults $AuditResults -IncludeDetailedAnalysis:$IncludePIMAnalysis
        principalAnalysis = Get-PrincipalAnalysis -AuditResults $AuditResults
        crossServiceAnalysis = Get-CrossServiceAnalysis -AuditResults $AuditResults
        securityAlerts = Get-SecurityAlerts -AuditResults $AuditResults -Stats $stats
        recommendations = Get-SecurityRecommendations -AuditResults $AuditResults -Stats $stats
        assignments = Get-FormattedAssignments -AuditResults $AuditResults
    }
    
    # Add compliance analysis if requested
    if ($IncludeComplianceAnalysis) {
        $report.complianceAnalysis = Get-ComplianceAnalysis -AuditResults $AuditResults -Stats $stats
    }
    
    try {
        $jsonOutput = $report | ConvertTo-Json -Depth 15
        $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "✓ Enhanced JSON report generated: $OutputPath" -ForegroundColor Green
        Show-ReportSummary -Report $report -OutputPath $OutputPath
        
        return $OutputPath
    }
    catch {
        Write-Error "Failed to generate enhanced JSON report: $($_.Exception.Message)"
        return $null
    }
}

function Get-M365RoleAnalysis {
    param(
        [Parameter(Mandatory = $true)]
        [array]$AuditResults,
        [switch]$IncludePIMAnalysis,
        [switch]$IncludeIntuneAnalysis,
        [switch]$IncludePowerPlatformAnalysis,
        [switch]$IncludeExchangeAnalysis,
        [switch]$ShowDetailedRecommendations,
        [switch]$ReturnStructuredData
    )
    
    Write-Host "=== M365 Comprehensive Role Analysis ===" -ForegroundColor Green
    
    if ($AuditResults.Count -eq 0) {
        Write-Warning "No audit results provided"
        return
    }
    
    # Use centralized statistics calculation from core functions
    Write-Host ""
    Write-Host "Calculating comprehensive statistics..." -ForegroundColor Cyan
    $stats = Get-AuditStatistics -AuditResults $AuditResults
    
    # Initialize analysis results object
    $analysisResults = @{
        Summary = $stats
        RoleSprawl = @{}
        OrphanedAccounts = @{}
        PrivilegeEscalation = @{}
        ServiceSpecific = @{}
        CrossService = @{}
        PIM = @{}
        Intune = @{}
        PowerPlatform = @{}
        Exchange = @{}
        Security = @{}
        Recommendations = @()
        ComplianceAnalysis = @{}
        SecurityAlerts = @{}
    }
    
    # === BASIC SUMMARY ANALYSIS ===
    Write-Host ""
    Write-Host "Basic Summary Analysis:" -ForegroundColor Cyan
    Write-Host "Total Assignments: $($stats.totalAssignments)" -ForegroundColor White
    Write-Host "Unique Users: $($stats.uniqueUsers)" -ForegroundColor White
    Write-Host "Services Audited: $($stats.servicesAudited)" -ForegroundColor White
    Write-Host "Authentication Methods:" -ForegroundColor White
    foreach ($authType in $stats.authTypes) {
        $color = if ($authType.Name -eq "Certificate") { "Green" } elseif ($authType.Name -eq "ClientSecret") { "Yellow" } else { "White" }
        Write-Host "  $($authType.Name): $($authType.Count)" -ForegroundColor $color
    }
    
    # === ROLE SPRAWL ANALYSIS ===
    Write-Host ""
    Write-Host "Role Sprawl Analysis:" -ForegroundColor Cyan
    $usersWithMultipleRoles = $AuditResults | Group-Object UserPrincipalName | Where-Object { 
        $_.Name -and $_.Name -ne "Unknown" -and $_.Count -gt 5 
    } | Sort-Object Count -Descending
    
    $analysisResults.RoleSprawl = @{
        UsersWithExcessiveRoles = $usersWithMultipleRoles
        ThresholdExceeded = $usersWithMultipleRoles.Count
    }
    
    if ($usersWithMultipleRoles.Count -gt 0) {
        Write-Host "⚠️ Users with excessive role assignments (>5 roles): $($usersWithMultipleRoles.Count)" -ForegroundColor Yellow
        foreach ($user in $usersWithMultipleRoles | Select-Object -First 10) {
            Write-Host "  $($user.Name): $($user.Count) roles" -ForegroundColor White
            
            # Show role distribution for top users
            $userRoles = $AuditResults | Where-Object { $_.UserPrincipalName -eq $user.Name }
            $rolesByService = $userRoles | Group-Object Service
            Write-Host "    Services: $($rolesByService.Name -join ', ')" -ForegroundColor Gray
        }
        
        $analysisResults.Recommendations += "Review users with excessive role assignments for principle of least privilege"
    }
    else {
        Write-Host "✓ No users found with excessive role assignments" -ForegroundColor Green
    }
    
    # === ORPHANED ACCOUNTS ANALYSIS ===
    Write-Host ""
    Write-Host "Orphaned Accounts Analysis:" -ForegroundColor Cyan
    
    $analysisResults.OrphanedAccounts = @{
        DisabledUsers = $stats.disabledUsers
        InactiveUsers = $stats.usersWithoutRecentSignIn
        SystemAccounts = $stats.systemGeneratedAccounts
    }
    
    if ($stats.disabledUsers.Count -gt 0) {
        Write-Host "⚠️ Disabled users with active roles: $($stats.disabledUsers.Count)" -ForegroundColor Red
        $disabledUsersGrouped = $stats.disabledUsers | Group-Object UserPrincipalName
        foreach ($user in $disabledUsersGrouped | Select-Object -First 5) {
            if ($user.Name -and $user.Name -ne "Unknown") {
                Write-Host "  $($user.Name): $($user.Count) active role(s)" -ForegroundColor Yellow
            }
        }
        $analysisResults.Recommendations += "Remove role assignments from disabled user accounts"
    }
    else {
        Write-Host "✓ No disabled users with active roles found" -ForegroundColor Green
    }
    
    if ($stats.usersWithoutRecentSignIn.Count -gt 0) {
        Write-Host "⚠️ Users with roles but no sign-in in 90+ days: $($stats.usersWithoutRecentSignIn.Count)" -ForegroundColor Yellow
        $analysisResults.Recommendations += "Review role assignments for users without recent sign-in activity"
    }
    
    if ($stats.systemGeneratedAccounts.Count -gt 0) {
        Write-Host "ℹ️ System-generated accounts/policies: $($stats.systemGeneratedAccounts.Count)" -ForegroundColor Cyan
    }
    
    # === PRIVILEGE ESCALATION ANALYSIS ===
    Write-Host ""
    Write-Host "Privilege Escalation Analysis:" -ForegroundColor Cyan
    
    $analysisResults.PrivilegeEscalation = @{
        GlobalAdmins = $stats.globalAdmins
        PrivilegedRoles = $stats.privilegedRoles
        SecurityRoles = $stats.securityRoles
        ComplianceRoles = $stats.complianceRoles
    }
    
    Write-Host "Global Administrators: $($stats.globalAdmins.Count)" -ForegroundColor $(if ($stats.globalAdmins.Count -gt 5) { "Red" } else { "Green" })
    Write-Host "Other Administrative Roles: $($stats.privilegedRoles.Count)" -ForegroundColor Gray
    Write-Host "Security-related Roles: $($stats.securityRoles.Count)" -ForegroundColor Gray
    Write-Host "Compliance-related Roles: $($stats.complianceRoles.Count)" -ForegroundColor Gray
    
    if ($stats.globalAdmins.Count -gt 5) {
        $analysisResults.Recommendations += "Reduce Global Administrator count to 5 or fewer (currently $($stats.globalAdmins.Count))"
    }
    
    # === SERVICE-SPECIFIC ANALYSIS ===
    Write-Host ""
    Write-Host "Service-Specific Analysis:" -ForegroundColor Cyan
    
    # Use the enhanced service analysis function from core
    $analysisResults.ServiceSpecific = Get-ServiceAnalysis -AuditResults $AuditResults -IncludeExchangeAnalysis:$IncludeExchangeAnalysis
    
    # Display service analysis summary
    foreach ($serviceName in $analysisResults.ServiceSpecific.Keys) {
        $serviceData = $analysisResults.ServiceSpecific[$serviceName]
        Write-Host "$serviceName`: $($serviceData.totalAssignments) assignments, $($serviceData.uniqueUsers) users" -ForegroundColor White
        Write-Host "  Top Role: $($serviceData.topRole)" -ForegroundColor Gray
        
        # Display service-specific insights
        if ($serviceData.ContainsKey('exchangeAnalysis')) {
            Write-Host "  Exchange: $($serviceData.exchangeAnalysis.roleGroupAssignments) role groups, $($serviceData.exchangeAnalysis.onPremisesSyncedUsers) synced users" -ForegroundColor Gray
        }
        if ($serviceData.ContainsKey('intuneAnalysis')) {
            Write-Host "  Intune: $($serviceData.intuneAnalysis.rbacAssignments) RBAC, $($serviceData.intuneAnalysis.serviceAdministrators) service admins" -ForegroundColor Gray
        }
        if ($serviceData.ContainsKey('sharePointAnalysis')) {
            Write-Host "  SharePoint: $($serviceData.sharePointAnalysis.uniqueSites) sites, $($serviceData.sharePointAnalysis.siteCollectionAdmins) site admins" -ForegroundColor Gray
        }
    }
    
    # === CROSS-SERVICE PRIVILEGE ANALYSIS ===
    Write-Host ""
    Write-Host "Cross-Service Privilege Analysis:" -ForegroundColor Cyan
    
    # Use the cross-service analysis function from core
    $analysisResults.CrossService = Get-CrossServiceAnalysis -AuditResults $AuditResults
    
    Write-Host "Users with roles across multiple services: $($analysisResults.CrossService.usersWithMultipleServices)" -ForegroundColor White
    Write-Host "Exchange + Azure AD combinations: $($analysisResults.CrossService.exchangeAzureADCombinations)" -ForegroundColor Gray
    Write-Host "Exchange + Purview combinations: $($analysisResults.CrossService.exchangePurviewCombinations)" -ForegroundColor Gray
    
    if ($analysisResults.CrossService.usersWithMultipleServices -gt 0) {
        $analysisResults.Recommendations += "Review users with high-risk cross-service role combinations"
    }
    
    # === PIM ANALYSIS ===
    if ($IncludePIMAnalysis) {
        Write-Host ""
        Write-Host "PIM (Privileged Identity Management) Analysis:" -ForegroundColor Cyan
        
        # Use the enhanced PIM analysis function from core
        $analysisResults.PIM = Get-PIMAnalysis -AuditResults $AuditResults -IncludeDetailedAnalysis:$true
        
        Write-Host "PIM Enabled: $($analysisResults.PIM.enabled)" -ForegroundColor $(if($analysisResults.PIM.enabled) {"Green"} else {"Yellow"})
        Write-Host "PIM Eligible Assignments: $($analysisResults.PIM.totalEligible)" -ForegroundColor $(if($analysisResults.PIM.totalEligible -gt 0) {"Green"} else {"Yellow"})
        Write-Host "PIM Active Assignments: $($analysisResults.PIM.totalActive)" -ForegroundColor White
        
        if ($analysisResults.PIM.detailed) {
            Write-Host "Expiring within 30 days: $($analysisResults.PIM.detailed.eligible.expiringWithin30Days)" -ForegroundColor $(if($analysisResults.PIM.detailed.eligible.expiringWithin30Days -gt 0) {"Yellow"} else {"Green"})
        }
        
        # PIM recommendations
        if (-not $analysisResults.PIM.enabled) {
            $analysisResults.Recommendations += "Consider implementing PIM for eligible assignments to reduce standing privileges"
        }
        
        if ($analysisResults.PIM.detailed.eligible.expiringWithin30Days -gt 0) {
            $analysisResults.Recommendations += "Review and renew expiring PIM assignments"
        }
    }
    
    # === INTUNE-SPECIFIC ANALYSIS ===
    if ($IncludeIntuneAnalysis) {
        Write-Host ""
        Write-Host "Intune-Specific Analysis:" -ForegroundColor Cyan
        
        $intuneResults = $AuditResults | Where-Object { $_.Service -eq "Microsoft Intune" }
        if ($intuneResults.Count -gt 0) {
            # Use the Intune analysis function from core if available, otherwise use existing logic
            if ($analysisResults.ServiceSpecific.ContainsKey('Microsoft Intune') -and 
                $analysisResults.ServiceSpecific['Microsoft Intune'].ContainsKey('intuneAnalysis')) {
                
                $intuneAnalysis = $analysisResults.ServiceSpecific['Microsoft Intune'].intuneAnalysis
                $analysisResults.Intune = $intuneAnalysis
                
                Write-Host "Total Intune Assignments: $($intuneResults.Count)" -ForegroundColor White
                Write-Host "RBAC Assignments: $($intuneAnalysis.rbacAssignments)" -ForegroundColor White
                Write-Host "Azure AD Assignments: $($intuneAnalysis.azureADAssignments)" -ForegroundColor White
                Write-Host "Service Administrators: $($intuneAnalysis.serviceAdministrators)" -ForegroundColor $(if($intuneAnalysis.serviceAdministrators -le 3) {"Green"} else {"Yellow"})
                Write-Host "Built-in Roles: $($intuneAnalysis.builtInRoles)" -ForegroundColor White
                Write-Host "Custom Roles: $($intuneAnalysis.customRoles)" -ForegroundColor White
                
                # Intune-specific recommendations
                if ($intuneAnalysis.serviceAdministrators -gt 3) {
                    $analysisResults.Recommendations += "Consider reducing Intune Service Administrator count (currently $($intuneAnalysis.serviceAdministrators))"
                }
                
                if ($intuneAnalysis.azureADAssignments -gt $intuneAnalysis.rbacAssignments) {
                    $analysisResults.Recommendations += "Consider using Intune RBAC roles instead of Azure AD roles for better granularity"
                }
                
                if ($intuneAnalysis.customRoles -eq 0 -and $intuneResults.Count -gt 20) {
                    $analysisResults.Recommendations += "Consider creating custom Intune roles for specific administrative needs"
                }
            }
        }
        else {
            Write-Host "No Intune assignments found in audit results" -ForegroundColor Yellow
        }
    }
    
    # === POWER PLATFORM ANALYSIS ===
    if ($IncludePowerPlatformAnalysis) {
        Write-Host ""
        Write-Host "Power Platform Analysis:" -ForegroundColor Cyan
        
        $powerPlatformResults = $AuditResults | Where-Object { $_.Service -eq "Power Platform" }
        if ($powerPlatformResults.Count -gt 0) {
            $powerPlatformAdmins = $powerPlatformResults | Where-Object { $_.RoleName -eq "Power Platform Administrator" }
            $dynamicsAdmins = $powerPlatformResults | Where-Object { $_.RoleName -like "*Dynamics*" }
            $powerBIAdmins = $powerPlatformResults | Where-Object { $_.RoleName -like "*Power BI*" }
            $principalTypes = $powerPlatformResults | Group-Object PrincipalType
            
            $analysisResults.PowerPlatform = @{
                TotalAssignments = $powerPlatformResults.Count
                PowerPlatformAdmins = $powerPlatformAdmins
                DynamicsAdmins = $dynamicsAdmins
                PowerBIAdmins = $powerBIAdmins
                PrincipalTypes = $principalTypes
            }
            
            Write-Host "Total Power Platform Assignments: $($powerPlatformResults.Count)" -ForegroundColor White
            Write-Host "Power Platform Administrators: $($powerPlatformAdmins.Count)" -ForegroundColor White
            Write-Host "Dynamics 365 Administrators: $($dynamicsAdmins.Count)" -ForegroundColor White
            Write-Host "Power BI Administrators: $($powerBIAdmins.Count)" -ForegroundColor White
            
            Write-Host "Principal Types:" -ForegroundColor Cyan
            foreach ($principalType in $principalTypes) {
                Write-Host "  $($principalType.Name): $($principalType.Count)" -ForegroundColor Gray
            }
            
            # Check for service principals with Power Platform access
            $servicePrincipals = $powerPlatformResults | Where-Object { $_.PrincipalType -eq "ServicePrincipal" }
            if ($servicePrincipals.Count -gt 0) {
                Write-Host "⚠️ Service Principals with Power Platform access: $($servicePrincipals.Count)" -ForegroundColor Yellow
                $analysisResults.Recommendations += "Review service principal access to Power Platform resources"
            }
        }
        else {
            Write-Host "No Power Platform assignments found in audit results" -ForegroundColor Yellow
        }
    }
    
    # === SECURITY ANALYSIS ===
    Write-Host ""
    Write-Host "Security Analysis:" -ForegroundColor Cyan
    
    # Use the security alerts function from core
    $analysisResults.SecurityAlerts = Get-SecurityAlerts -AuditResults $AuditResults -Stats $stats
    $analysisResults.Security = @{
        CertificateAuthCount = ($stats.authTypes | Where-Object { $_.Name -eq "Certificate" }).Count
        ClientSecretAuthCount = ($stats.authTypes | Where-Object { $_.Name -eq "ClientSecret" }).Count
        SecurityScore = 0
        GlobalAdminCount = $analysisResults.SecurityAlerts.globalAdminCount
        DisabledUsersWithRoles = $analysisResults.SecurityAlerts.disabledUsersWithRoles
        CertificateBasedAuthEnabled = $analysisResults.SecurityAlerts.certificateBasedAuth
        ClientSecretAuthUsage = $analysisResults.SecurityAlerts.clientSecretAuth
    }
    
    # Calculate basic security score
    $securityScore = 0
    if ($analysisResults.Security.CertificateAuthCount -gt 0 -and $analysisResults.Security.ClientSecretAuthCount -eq 0) { $securityScore += 25 }
    if ($stats.globalAdmins.Count -le 5) { $securityScore += 25 }
    if ($stats.disabledUsers.Count -eq 0) { $securityScore += 25 }
    if ($stats.pimEligible.Count -gt 0) { $securityScore += 25 }
    
    $analysisResults.Security.SecurityScore = $securityScore
    
    Write-Host "Certificate Authentication: $($analysisResults.Security.CertificateAuthCount)" -ForegroundColor Green
    Write-Host "Client Secret Authentication: $($analysisResults.Security.ClientSecretAuthCount)" -ForegroundColor $(if($analysisResults.Security.ClientSecretAuthCount -eq 0) {"Green"} else {"Yellow"})
    Write-Host "Security Score: $securityScore/100" -ForegroundColor $(if($securityScore -ge 75) {"Green"} elseif($securityScore -ge 50) {"Yellow"} else {"Red"})
    
    # Display security alerts
    if ($analysisResults.SecurityAlerts.critical.Count -gt 0) {
        Write-Host "CRITICAL ALERTS:" -ForegroundColor Red
        foreach ($alert in $analysisResults.SecurityAlerts.critical) {
            Write-Host "  • $alert" -ForegroundColor Red
        }
    }
    
    if ($analysisResults.SecurityAlerts.high.Count -gt 0) {
        Write-Host "HIGH ALERTS:" -ForegroundColor Yellow
        foreach ($alert in $analysisResults.SecurityAlerts.high) {
            Write-Host "  • $alert" -ForegroundColor Yellow
        }
    }
    
    # === COMPLIANCE ANALYSIS ===
    Write-Host ""
    Write-Host "Compliance Analysis:" -ForegroundColor Cyan
    
    # Use the compliance analysis function from core
    $analysisResults.ComplianceAnalysis = Get-ComplianceAnalysis -AuditResults $AuditResults -Stats $stats
    
    $privAccess = $analysisResults.ComplianceAnalysis.privilegedAccessCompliance
    Write-Host "Global Admin Compliance: $(if($privAccess.globalAdminLimit.compliant) {"✓ Compliant"} else {"⚠ Non-compliant"})" -ForegroundColor $(if($privAccess.globalAdminLimit.compliant) {"Green"} else {"Red"})
    Write-Host "PIM Implementation: $(if($privAccess.pimImplementation.compliant) {"✓ Implemented"} else {"⚠ Not implemented"})" -ForegroundColor $(if($privAccess.pimImplementation.compliant) {"Green"} else {"Yellow"})
    Write-Host "Disabled Account Cleanup: $(if($privAccess.disabledAccountCleanup.compliant) {"✓ Clean"} else {"⚠ Needs cleanup"})" -ForegroundColor $(if($privAccess.disabledAccountCleanup.compliant) {"Green"} else {"Red"})
    
    $authCompliance = $analysisResults.ComplianceAnalysis.authenticationCompliance
    Write-Host "Certificate Auth Usage: $($authCompliance.certificateBasedAuth.percentage)%" -ForegroundColor $(if($authCompliance.certificateBasedAuth.compliant) {"Green"} else {"Yellow"})
    
    # === DETAILED RECOMMENDATIONS ===
    if ($ShowDetailedRecommendations) {
        Write-Host ""
        Write-Host "=== DETAILED RECOMMENDATIONS ===" -ForegroundColor Yellow
        
        # Use the recommendations function from core
        $detailedRecommendations = Get-SecurityRecommendations -AuditResults $AuditResults -Stats $stats
        
        if ($detailedRecommendations.immediate.Count -gt 0) {
            Write-Host "IMMEDIATE ACTION REQUIRED:" -ForegroundColor Red
            foreach ($rec in $detailedRecommendations.immediate) {
                Write-Host "  • $rec" -ForegroundColor White
            }
        }
        
        if ($detailedRecommendations.shortTerm.Count -gt 0) {
            Write-Host "SHORT-TERM (1-3 months):" -ForegroundColor Yellow
            foreach ($rec in $detailedRecommendations.shortTerm) {
                Write-Host "  • $rec" -ForegroundColor White
            }
        }
        
        if ($detailedRecommendations.longTerm.Count -gt 0) {
            Write-Host "LONG-TERM (3+ months):" -ForegroundColor Cyan
            foreach ($rec in $detailedRecommendations.longTerm) {
                Write-Host "  • $rec" -ForegroundColor White
            }
        }
        
        # Merge recommendations from detailed analysis
        $analysisResults.Recommendations += $detailedRecommendations.immediate
        $analysisResults.Recommendations += $detailedRecommendations.shortTerm
        $analysisResults.Recommendations += $detailedRecommendations.longTerm
    }
    
    Write-Host ""
    Write-Host "✓ Role analysis completed successfully" -ForegroundColor Green
    Write-Host "Analysis covered $($AuditResults.Count) role assignments across $($stats.servicesAudited) services" -ForegroundColor Cyan
    
    # Return structured data if requested, otherwise return analysis results
    if ($ReturnStructuredData) {
        return $analysisResults
    }
    
    return $analysisResults
}

# Helper function to get audit statistics (if not already in core functions)


function Get-M365ComplianceGaps {
    param(
        [Parameter(Mandatory = $true)]
        [array]$AuditResults,
        [switch]$IncludeDetailedAnalysis,
        [switch]$IncludePIMGaps,
        [switch]$IncludeIntuneGaps,
        [switch]$IncludePowerPlatformGaps
    )
    
    Write-Host "=== M365 Comprehensive Compliance Gap Analysis ===" -ForegroundColor Green
    
    if ($AuditResults.Count -eq 0) {
        Write-Warning "No audit results provided"
        return @()
    }
    
    $gaps = @()
    $criticalGaps = @()
    $highGaps = @()
    $mediumGaps = @()
    $lowGaps = @()
    
    # === IDENTITY GOVERNANCE GAPS ===
    Write-Host "Analyzing Identity Governance..." -ForegroundColor Cyan
    
    # Check Global Admin count
    $globalAdmins = $AuditResults | Where-Object { $_.RoleName -eq "Global Administrator" }
    if ($globalAdmins.Count -gt 5) {
        $gap = [PSCustomObject]@{
            Category = "Identity Governance"
            Issue = "Excessive Global Administrators"
            Details = "$($globalAdmins.Count) Global Admin accounts (recommended: ≤5)"
            Severity = "Critical"
            Recommendation = "Reduce Global Admin count using principle of least privilege and role-specific admin roles"
            AffectedUsers = ($globalAdmins | Select-Object -ExpandProperty UserPrincipalName) -join "; "
            ComplianceFramework = "ISO 27001, NIST, CIS Controls"
            RemediationSteps = @(
                "1. Review each Global Admin's actual responsibilities",
                "2. Assign appropriate role-specific admin roles",
                "3. Remove Global Admin role where not required",
                "4. Implement break-glass accounts for emergency access"
            )
        }
        $criticalGaps += $gap
        $gaps += $gap
    }
    
    # Check for disabled users with roles
    $disabledWithRoles = $AuditResults | Where-Object { $_.UserEnabled -eq $false }
    if ($disabledWithRoles.Count -gt 0) {
        $affectedUsers = ($disabledWithRoles | Group-Object UserPrincipalName | Select-Object -ExpandProperty Name) -join "; "
        $gap = [PSCustomObject]@{
            Category = "Access Management"
            Issue = "Disabled Users with Active Roles"
            Details = "$($disabledWithRoles.Count) disabled users still have role assignments"
            Severity = "High"
            Recommendation = "Implement automated role removal process for disabled accounts"
            AffectedUsers = $affectedUsers
            ComplianceFramework = "SOX, PCI DSS, GDPR"
            RemediationSteps = @(
                "1. Identify all disabled users with role assignments",
                "2. Remove role assignments from disabled accounts",
                "3. Implement automated workflow to remove roles when accounts are disabled",
                "4. Regular review of disabled account permissions"
            )
        }
        $highGaps += $gap
        $gaps += $gap
    }
    
    # === AUTHENTICATION SECURITY GAPS ===
    Write-Host "Analyzing Authentication Security..." -ForegroundColor Cyan
    
    # Check authentication methods
    $clientSecretAuth = $AuditResults | Where-Object { $_.AuthenticationType -eq "ClientSecret" }
    if ($clientSecretAuth.Count -gt 0) {
        $gap = [PSCustomObject]@{
            Category = "Authentication Security"
            Issue = "Client Secret Authentication Usage"
            Details = "$($clientSecretAuth.Count) connections use client secret instead of certificate authentication"
            Severity = "Medium"
            Recommendation = "Migrate to certificate-based authentication for enhanced security"
            AffectedUsers = "Application Authentication"
            ComplianceFramework = "NIST Cybersecurity Framework, Zero Trust"
            RemediationSteps = @(
                "1. Generate X.509 certificates for app registrations",
                "2. Upload certificates to Azure AD app registrations",
                "3. Update automation scripts to use certificate authentication",
                "4. Remove client secrets after migration"
            )
        }
        $mediumGaps += $gap
        $gaps += $gap
    }
    
    # === PIM AND PRIVILEGED ACCESS GAPS ===
    if ($IncludePIMGaps) {
        Write-Host "Analyzing Privileged Identity Management..." -ForegroundColor Cyan
        
        # Check for PIM usage
        $eligibleAssignments = $AuditResults | Where-Object { $_.AssignmentType -like "*Eligible*" }
        $activeAssignments = $AuditResults | Where-Object { 
            $_.AssignmentType -eq "Active" -or 
            $_.AssignmentType -eq "Azure AD Role" -or
            $_.AssignmentType -eq "Intune RBAC"
        }
        
        if ($eligibleAssignments.Count -eq 0 -and $activeAssignments.Count -gt 0) {
            $gap = [PSCustomObject]@{
                Category = "Privileged Access Management"
                Issue = "No PIM Eligible Assignments"
                Details = "All $($activeAssignments.Count) privileged roles are permanently assigned (no PIM eligible assignments found)"
                Severity = "High"
                Recommendation = "Implement Privileged Identity Management (PIM) for just-in-time access to privileged roles"
                AffectedUsers = "All privileged users"
                ComplianceFramework = "NIST 800-53, ISO 27001, Zero Trust"
                RemediationSteps = @(
                    "1. Enable Azure AD PIM licensing",
                    "2. Identify roles suitable for PIM eligible assignments",
                    "3. Convert permanent assignments to eligible assignments",
                    "4. Configure approval workflows and access reviews"
                )
            }
            $highGaps += $gap
            $gaps += $gap
        }
        
        # Check PIM adoption rate
        $totalPrivilegedAssignments = $eligibleAssignments.Count + $activeAssignments.Count
        if ($totalPrivilegedAssignments -gt 0) {
            $pimAdoptionRate = [math]::Round(($eligibleAssignments.Count / $totalPrivilegedAssignments) * 100, 2)
            if ($pimAdoptionRate -lt 30 -and $eligibleAssignments.Count -gt 0) {
                $gap = [PSCustomObject]@{
                    Category = "Privileged Access Management"
                    Issue = "Low PIM Adoption Rate"
                    Details = "PIM adoption rate is only $pimAdoptionRate% ($($eligibleAssignments.Count) eligible vs $($activeAssignments.Count) permanent)"
                    Severity = "Medium"
                    Recommendation = "Expand PIM usage to cover more privileged roles"
                    AffectedUsers = "Privileged role users"
                    ComplianceFramework = "Zero Trust, NIST"
                    RemediationSteps = @(
                        "1. Review current permanently assigned roles",
                        "2. Evaluate which roles can be converted to eligible",
                        "3. Implement phased PIM rollout",
                        "4. Train users on PIM activation process"
                    )
                }
                $mediumGaps += $gap
                $gaps += $gap
            }
        }
        
        # Check for expiring PIM assignments
        $expiringPIMAssignments = $AuditResults | Where-Object { 
            $_.PIMEndDateTime -and 
            [DateTime]$_.PIMEndDateTime -lt (Get-Date).AddDays(30)
        }
        
        if ($expiringPIMAssignments.Count -gt 0) {
            $gap = [PSCustomObject]@{
                Category = "Privileged Access Management"
                Issue = "Expiring PIM Assignments"
                Details = "$($expiringPIMAssignments.Count) PIM assignments expire within 30 days"
                Severity = "Medium"
                Recommendation = "Review and renew expiring PIM assignments to prevent access disruption"
                AffectedUsers = ($expiringPIMAssignments | Select-Object -ExpandProperty UserPrincipalName -Unique) -join "; "
                ComplianceFramework = "Access Management"
                RemediationSteps = @(
                    "1. Review expiring PIM assignments",
                    "2. Validate continued business need",
                    "3. Renew or remove assignments as appropriate",
                    "4. Implement automated renewal notifications"
                )
            }
            $mediumGaps += $gap
            $gaps += $gap
        }
    }
    
    # === ACCOUNT MANAGEMENT GAPS ===
    Write-Host "Analyzing Account Management..." -ForegroundColor Cyan
    
    # Check for service accounts or shared accounts
    $potentialServiceAccounts = $AuditResults | Where-Object { 
        $_.UserPrincipalName -like "*service*" -or 
        $_.UserPrincipalName -like "*admin*" -or
        $_.UserPrincipalName -like "*shared*" -or
        $_.UserPrincipalName -like "*system*"
    } | Where-Object { $_.UserPrincipalName -ne "System Generated" }
    
    if ($potentialServiceAccounts.Count -gt 0) {
        $serviceAccountUsers = ($potentialServiceAccounts | Group-Object UserPrincipalName | Select-Object -ExpandProperty Name) -join "; "
        $gap = [PSCustomObject]@{
            Category = "Account Management"
            Issue = "Potential Service/Shared Accounts"
            Details = "Found $($potentialServiceAccounts.Count) accounts that may be service/shared accounts with privileged access"
            Severity = "Medium"
            Recommendation = "Review account naming conventions, implement managed identities where possible"
            AffectedUsers = $serviceAccountUsers
            ComplianceFramework = "CIS Controls, NIST"
            RemediationSteps = @(
                "1. Review account usage patterns and ownership",
                "2. Convert to managed identities where applicable",
                "3. Implement proper service account governance",
                "4. Regular review of service account permissions"
            )
        }
        $mediumGaps += $gap
        $gaps += $gap
    }
    
    # Check for users without recent sign-in
    $usersWithoutRecentSignIn = $AuditResults | Where-Object { 
        $_.LastSignIn -and $_.LastSignIn -lt (Get-Date).AddDays(-90) -and $_.UserEnabled -eq $true
    }
    
    if ($usersWithoutRecentSignIn.Count -gt 0) {
        $inactiveUsers = ($usersWithoutRecentSignIn | Group-Object UserPrincipalName | Select-Object -ExpandProperty Name) -join "; "
        $gap = [PSCustomObject]@{
            Category = "Access Management"
            Issue = "Inactive Users with Roles"
            Details = "$($usersWithoutRecentSignIn.Count) enabled users with roles haven't signed in for 90+ days"
            Severity = "Medium"
            Recommendation = "Review and remove role assignments for inactive users"
            AffectedUsers = $inactiveUsers
            ComplianceFramework = "SOX, Access Management"
            RemediationSteps = @(
                "1. Contact users to verify continued need",
                "2. Remove role assignments for confirmed inactive users",
                "3. Implement regular inactive user reviews",
                "4. Consider conditional access policies"
            )
        }
        $mediumGaps += $gap
        $gaps += $gap
    }
    
    # === LEAST PRIVILEGE GAPS ===
    Write-Host "Analyzing Least Privilege Compliance..." -ForegroundColor Cyan
    
    # Check for excessive scope assignments
    $organizationWideRoles = $AuditResults | Where-Object { 
        $_.Scope -eq "Organization" -or $_.Scope -eq "/" -or [string]::IsNullOrEmpty($_.Scope)
    }
    $scopedRoles = $AuditResults | Where-Object { 
        ![string]::IsNullOrEmpty($_.Scope) -and $_.Scope -ne "Organization" -and $_.Scope -ne "/"
    }
    
    if ($organizationWideRoles.Count -gt ($scopedRoles.Count * 2) -and $organizationWideRoles.Count -gt 20) {
        $gap = [PSCustomObject]@{
            Category = "Least Privilege"
            Issue = "Excessive Organization-Wide Role Assignments"
            Details = "$($organizationWideRoles.Count) organization-wide roles vs $($scopedRoles.Count) scoped roles"
            Severity = "Low"
            Recommendation = "Consider implementing scoped role assignments where appropriate to limit access"
            AffectedUsers = "Multiple users"
            ComplianceFramework = "Principle of Least Privilege"
            RemediationSteps = @(
                "1. Review organization-wide role assignments",
                "2. Identify opportunities for scope-specific assignments",
                "3. Implement resource-scoped roles where possible",
                "4. Regular review of role scope requirements"
            )
        }
        $lowGaps += $gap
        $gaps += $gap
    }
    
    # Check for role sprawl
    $usersWithMultipleRoles = $AuditResults | Where-Object { 
        $_.UserPrincipalName -and $_.UserPrincipalName -ne "Unknown" -and $_.UserPrincipalName -ne "System Generated"
    } | Group-Object UserPrincipalName | Where-Object { $_.Count -gt 5 }
    
    if ($usersWithMultipleRoles.Count -gt 0) {
        $sprawlUsers = ($usersWithMultipleRoles | Select-Object -First 5 | ForEach-Object { "$($_.Name) ($($_.Count) roles)" }) -join "; "
        $gap = [PSCustomObject]@{
            Category = "Role Management"
            Issue = "Role Sprawl Detected"
            Details = "$($usersWithMultipleRoles.Count) users have more than 5 role assignments"
            Severity = "Medium"
            Recommendation = "Review users with excessive role assignments for consolidation opportunities"
            AffectedUsers = $sprawlUsers
            ComplianceFramework = "Least Privilege, Role-Based Access Control"
            RemediationSteps = @(
                "1. Analyze role combinations for each user",
                "2. Identify overlapping or redundant permissions",
                "3. Consolidate roles where possible",
                "4. Create custom roles for specific needs"
            )
        }
        $mediumGaps += $gap
        $gaps += $gap
    }
    
    # === INTUNE-SPECIFIC COMPLIANCE GAPS ===
    if ($IncludeIntuneGaps) {
        Write-Host "Analyzing Intune Compliance..." -ForegroundColor Cyan
        
        $intuneResults = $AuditResults | Where-Object { $_.Service -eq "Microsoft Intune" }
        if ($intuneResults.Count -gt 0) {
            # Check Intune Service Administrator count
            $intuneServiceAdmins = $intuneResults | Where-Object { $_.RoleName -eq "Intune Service Administrator" }
            if ($intuneServiceAdmins.Count -gt 3) {
                $gap = [PSCustomObject]@{
                    Category = "Device Management"
                    Issue = "Excessive Intune Service Administrators"
                    Details = "$($intuneServiceAdmins.Count) Intune Service Administrators (recommended: ≤3)"
                    Severity = "Medium"
                    Recommendation = "Use Intune RBAC roles for granular permissions instead of broad service administrator role"
                    AffectedUsers = ($intuneServiceAdmins | Select-Object -ExpandProperty UserPrincipalName) -join "; "
                    ComplianceFramework = "Device Security, NIST"
                    RemediationSteps = @(
                        "1. Review Intune administrative requirements",
                        "2. Implement Intune RBAC roles for specific functions",
                        "3. Remove unnecessary Service Administrator roles",
                        "4. Train admins on scoped permissions"
                    )
                }
                $mediumGaps += $gap
                $gaps += $gap
            }
            
            # Check RBAC vs Azure AD role usage
            $intuneRBACAssignments = $intuneResults | Where-Object { $_.RoleType -eq "IntuneRBAC" }
            $intuneAzureADAssignments = $intuneResults | Where-Object { $_.RoleType -eq "AzureAD" }
            
            if ($intuneAzureADAssignments.Count -gt $intuneRBACAssignments.Count -and $intuneResults.Count -gt 10) {
                $gap = [PSCustomObject]@{
                    Category = "Device Management"
                    Issue = "Underutilized Intune RBAC"
                    Details = "$($intuneAzureADAssignments.Count) Azure AD roles vs $($intuneRBACAssignments.Count) Intune RBAC roles"
                    Severity = "Low"
                    Recommendation = "Leverage Intune RBAC for more granular, scope-specific permissions"
                    AffectedUsers = "Intune administrators"
                    ComplianceFramework = "Least Privilege"
                    RemediationSteps = @(
                        "1. Map current Azure AD roles to Intune RBAC equivalents",
                        "2. Create custom Intune roles for specific needs",
                        "3. Migrate to Intune RBAC where appropriate",
                        "4. Implement scope-based assignments"
                    )
                }
                $lowGaps += $gap
                $gaps += $gap
            }
            
            # Check for policy ownership and management
            $intunePolicyOwners = $intuneResults | Where-Object { $_.RoleType -eq "PolicyOwner" }
            if ($intunePolicyOwners.Count -eq 0) {
                $gap = [PSCustomObject]@{
                    Category = "Device Management"
                    Issue = "No Policy Ownership Tracking"
                    Details = "No Intune policy ownership information found"
                    Severity = "Low"
                    Recommendation = "Implement policy ownership tracking and governance"
                    AffectedUsers = "Policy administrators"
                    ComplianceFramework = "Change Management"
                    RemediationSteps = @(
                        "1. Document policy ownership and responsibilities",
                        "2. Implement policy change approval process",
                        "3. Regular review of policy configurations",
                        "4. Track policy creation and modification"
                    )
                }
                $lowGaps += $gap
                $gaps += $gap
            }
        }
    }
    
    # === POWER PLATFORM COMPLIANCE GAPS ===
    if ($IncludePowerPlatformGaps) {
        Write-Host "Analyzing Power Platform Compliance..." -ForegroundColor Cyan
        
        $powerPlatformResults = $AuditResults | Where-Object { $_.Service -eq "Power Platform" }
        if ($powerPlatformResults.Count -gt 0) {
            # Check for service principals with Power Platform access
            $servicePrincipals = $powerPlatformResults | Where-Object { $_.PrincipalType -eq "ServicePrincipal" }
            if ($servicePrincipals.Count -gt 0) {
                $spNames = ($servicePrincipals | Select-Object -ExpandProperty DisplayName -Unique) -join "; "
                $gap = [PSCustomObject]@{
                    Category = "Application Security"
                    Issue = "Service Principals with Power Platform Access"
                    Details = "$($servicePrincipals.Count) service principals have Power Platform administrative access"
                    Severity = "Medium"
                    Recommendation = "Review and validate service principal access to Power Platform resources"
                    AffectedUsers = $spNames
                    ComplianceFramework = "Application Security"
                    RemediationSteps = @(
                        "1. Review each service principal's business justification",
                        "2. Validate minimum required permissions",
                        "3. Implement managed identities where possible",
                        "4. Regular audit of application permissions"
                    )
                }
                $mediumGaps += $gap
                $gaps += $gap
            }
            
            # Check Power Platform administrator count
            $powerPlatformAdmins = $powerPlatformResults | Where-Object { $_.RoleName -eq "Power Platform Administrator" }
            if ($powerPlatformAdmins.Count -gt 5) {
                $gap = [PSCustomObject]@{
                    Category = "Power Platform Governance"
                    Issue = "Excessive Power Platform Administrators"
                    Details = "$($powerPlatformAdmins.Count) Power Platform Administrators (consider environment-specific roles)"
                    Severity = "Medium"
                    Recommendation = "Use environment-specific admin roles instead of tenant-wide Power Platform Administrator"
                    AffectedUsers = ($powerPlatformAdmins | Select-Object -ExpandProperty UserPrincipalName) -join "; "
                    ComplianceFramework = "Least Privilege"
                    RemediationSteps = @(
                        "1. Review Power Platform administrative requirements",
                        "2. Implement environment-specific roles",
                        "3. Use DLP policies for governance",
                        "4. Regular review of platform usage"
                    )
                }
                $mediumGaps += $gap
                $gaps += $gap
            }
        }
    }
    
    # === MULTI-SERVICE AND CROSS-PLATFORM GAPS ===
    Write-Host "Analyzing Cross-Service Security..." -ForegroundColor Cyan
    
    # Check for high-risk cross-service combinations
    $usersWithCrossServiceRoles = $AuditResults | Where-Object { 
        $_.UserPrincipalName -and $_.UserPrincipalName -ne "Unknown" -and $_.UserPrincipalName -ne "System Generated"
    } | Group-Object UserPrincipalName | Where-Object {
        ($_.Group | Group-Object Service).Count -gt 1
    }
    
    $highRiskCombinations = $usersWithCrossServiceRoles | Where-Object {
        $userServices = ($_.Group | Group-Object Service).Name
        ($userServices -contains "Microsoft Purview" -and $userServices -contains "Exchange Online") -or
        ($userServices -contains "Azure AD/Entra ID" -and $userServices -contains "SharePoint Online" -and $userServices -contains "Exchange Online") -or
        ($userServices -contains "Microsoft Intune" -and $userServices -contains "Azure AD/Entra ID" -and $_.Count -gt 8)
    }
    
    if ($highRiskCombinations.Count -gt 0) {
        $riskUsers = ($highRiskCombinations | Select-Object -First 3 | ForEach-Object { 
            $services = ($_.Group | Group-Object Service).Name -join ","
            "$($_.Name) [$services]"
        }) -join "; "
        
        $gap = [PSCustomObject]@{
            Category = "Cross-Service Security"
            Issue = "High-Risk Cross-Service Role Combinations"
            Details = "$($highRiskCombinations.Count) users have high-risk combinations of roles across multiple services"
            Severity = "High"
            Recommendation = "Review and segregate duties for users with extensive cross-service privileges"
            AffectedUsers = $riskUsers
            ComplianceFramework = "Segregation of Duties, SOX"
            RemediationSteps = @(
                "1. Review business justification for cross-service access",
                "2. Implement segregation of duties where possible",
                "3. Use separate accounts for different administrative functions",
                "4. Enhanced monitoring for high-privilege users"
            )
        }
        $highGaps += $gap
        $gaps += $gap
    }
    
    # === COMPLIANCE REPORTING AND SUMMARY ===
    Write-Host ""
    Write-Host "=== COMPLIANCE GAP SUMMARY ===" -ForegroundColor Yellow
    
    if ($gaps.Count -eq 0) {
        Write-Host "✓ No significant compliance gaps identified!" -ForegroundColor Green
        return @()
    }
    
    Write-Host "Total Gaps Found: $($gaps.Count)" -ForegroundColor White
    Write-Host "  Critical: $($criticalGaps.Count)" -ForegroundColor Red
    Write-Host "  High: $($highGaps.Count)" -ForegroundColor Red
    Write-Host "  Medium: $($mediumGaps.Count)" -ForegroundColor Yellow
    Write-Host "  Low: $($lowGaps.Count)" -ForegroundColor Cyan
    
    if ($IncludeDetailedAnalysis) {
        Write-Host ""
        Write-Host "=== DETAILED GAP ANALYSIS ===" -ForegroundColor Cyan
        
        if ($criticalGaps.Count -gt 0) {
            Write-Host "CRITICAL GAPS:" -ForegroundColor Red
            foreach ($gap in $criticalGaps) {
                Write-Host "  ⚠️ $($gap.Issue): $($gap.Details)" -ForegroundColor White
                Write-Host "     Recommendation: $($gap.Recommendation)" -ForegroundColor Gray
            }
        }
        
        if ($highGaps.Count -gt 0) {
            Write-Host "HIGH PRIORITY GAPS:" -ForegroundColor Red
            foreach ($gap in $highGaps) {
                Write-Host "  ⚠️ $($gap.Issue): $($gap.Details)" -ForegroundColor White
                Write-Host "     Recommendation: $($gap.Recommendation)" -ForegroundColor Gray
            }
        }
        
        if ($mediumGaps.Count -gt 0) {
            Write-Host "MEDIUM PRIORITY GAPS:" -ForegroundColor Yellow
            foreach ($gap in $mediumGaps) {
                Write-Host "  • $($gap.Issue): $($gap.Details)" -ForegroundColor White
                Write-Host "    Recommendation: $($gap.Recommendation)" -ForegroundColor Gray
            }
        }
        
        if ($lowGaps.Count -gt 0) {
            Write-Host "LOW PRIORITY GAPS:" -ForegroundColor Cyan
            foreach ($gap in $lowGaps) {
                Write-Host "  • $($gap.Issue): $($gap.Details)" -ForegroundColor White
                Write-Host "    Recommendation: $($gap.Recommendation)" -ForegroundColor Gray
            }
        }
    }
    
    # Compliance framework mapping
    Write-Host ""
    Write-Host "=== COMPLIANCE FRAMEWORK IMPACT ===" -ForegroundColor Cyan
    $frameworkImpact = $gaps | ForEach-Object { $_.ComplianceFramework -split ", " } | 
                      Group-Object | Sort-Object Count -Descending
    
    foreach ($framework in $frameworkImpact) {
        Write-Host "  $($framework.Name): $($framework.Count) gaps" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Priority Remediation Recommendations:" -ForegroundColor Yellow
    $priorityRecommendations = @()
    $priorityRecommendations += $criticalGaps | ForEach-Object { $_.Recommendation }
    $priorityRecommendations += $highGaps | ForEach-Object { $_.Recommendation }
    
    $priorityRecommendations | Select-Object -Unique | ForEach-Object {
        Write-Host "• $_" -ForegroundColor White
    }
    
    return $gaps
}

function Export-M365AuditExcelReport {
    param(
        [Parameter(Mandatory = $true)]
        [array]$AuditResults,
        
        [string]$OutputPath = ".\M365_Audit_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx",
        [string]$OrganizationName = "Organization",
        [switch]$AutoOpen
    )
    
    Write-Host "=== Generating Excel Audit Report ===" -ForegroundColor Green
    Write-Host "Output Path: $OutputPath" -ForegroundColor Cyan
    
    if ($AuditResults.Count -eq 0) {
        Write-Warning "No audit results provided"
        return
    }
    
    # Check if ImportExcel module is available
    if (-not (Get-Module -ListAvailable -Name "ImportExcel")) {
        Write-Host "ImportExcel module not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name ImportExcel -Force -AllowClobber -Scope CurrentUser
            Write-Host "✓ ImportExcel module installed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install ImportExcel module: $($_.Exception.Message)"
            return
        }
    }
    
    Import-Module ImportExcel -Force

    $StartRow = 1
    $StartColumn = 1

    $excel = Export-Excel -Path $OutputPath -WorksheetName "Summary" -PassThru
    
    try {
        # Remove existing file if it exists
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force
        }
        
        # Calculate statistics matching HTML report
        $totalAssignments = $AuditResults.Count
        $uniqueUsers = ($AuditResults | Where-Object { $_.UserPrincipalName -and $_.UserPrincipalName -ne "Unknown" } | 
                       Select-Object -Unique UserPrincipalName).Count
        $servicesAudited = ($AuditResults | Group-Object Service).Count
        $globalAdmins = $AuditResults | Where-Object { $_.RoleName -eq "Global Administrator" }
        $pimEligible = $AuditResults | Where-Object { $_.AssignmentType -like "*Eligible*" }
        $pimActive = $AuditResults | Where-Object { $_.AssignmentType -like "*Active (PIM*" }
        $services = $AuditResults | Group-Object Service | Sort-Object Count -Descending
        
        Write-Host "Creating Summary Dashboard..." -ForegroundColor Cyan
        $Summary = [Ordered]@{                                            
            "Total Assignments" = $totalAssignments
            "Unique Users" = $uniqueUsers
            "Services Audited" = $servicesAudited
            "Global Admins" = $globalAdmins.count
            "PIM Active" = $pimActive.Count
            "PIM Eligible" = $pimEligible.Count
        }

        $excel = $Summary.GetEnumerator() | Select-Object @{Name="Metric"; Expression={$_.Name}}, Value  | `
            Export-Excel    -ExcelPackage $excel `
                            -WorksheetName "Summary" `
                            -StartRow $StartRow `
                            -TableName 'Summary_Metrics' `
                            -Title 'Summary' `
                            -TitleSize 14 `
                            -TitleBold `
                            -PassThru
        
        
        $summaryCards = @()

        foreach ($service in $services) {
            $percentage = [math]::Round(($service.Count / $totalAssignments) * 100, 1)
            $summaryCards += [PSCustomObject]@{
                Service = $service.Name
                Assignments = $service.Count
                Percentage = "$percentage%"
            }
        }

        $StartRow += $Summary.Keys.Count + 3
        
        $Chart = New-ExcelChartDefinition -ChartType Pie `
                                            -XRange Service `
                                            -YRange Assignments `
                                            -Title "Service Assignment Distribution" `
                                            -TitleSize 10 `
                                            -Row ($StartRow - 1) `
                                            -Column ($StartColumn + 2) `
                                            -LegendSize 8 `
                                            -Width 200 `
                                            -Height 200

        $Excel = $summaryCards | Export-Excel   -ExcelPackage $excel `
                                                -WorksheetName 'Summary' `
                                                -StartRow $StartRow `
                                                -Title "Assignments" `
                                                -TableName 'Assignments' `
                                                -TitleBold `
                                                -TitleSize '14' `
                                                -AutoNameRange `
                                                -ExcelChartDefinition $Chart `
                                                -PassThru
        
        $StartRow += ($summaryCards.Count + 3)

        # Show statistics
        $Stats = Get-AuditStatistics -AuditResults $AuditResults 

        $Summary = Get-ReportSummary -AuditResults $AuditResults -Stats $Stats


        # Users with most roles
        $Chart = New-ExcelChartDefinition -ChartType BarStacked `
                                            -XRange 'Display_Name' `
                                            -YRange 'Number_Of_Roles' `
                                            -Title 'Users with Most Roles' `
                                            -TitleSize 10 `
                                            -Row ($StartRow ) `
                                            -RowOffSetPixels -10 `
                                            -Column ($StartColumn + 2) `
                                            -Width 750 `
                                            -Heigh 325 `
                                            -NoLegend `
    

        $excel = $Summary.usersWithMostRoles | Select-Object @{Name = 'Display Name'; Expression = {$_.DisplayName}}, `
                                        @{Name = 'User Principal Name'; Expression = {$_.userprincipalName}}, `
                                        @{Name = 'Number of Roles'; Expression = {$_.roleCount}} | `
                    Export-Excel -ExcelPackage $excel `
                                -WorksheetName 'Summary' `
                                -StartRow $StartRow `
                                -Title 'Users with Most Roles' `
                                -TableName 'ReportSummary' `
                                -TitleBold `
                                -TitleSize 14 `
                                -AutoNameRange `
                                -ExcelChartDefinition $Chart `
                                -PassThru -WarningAction SilentlyContinue
        
        $StartRow += ($Summary.usersWithMostRoles.Count + 3)

        # Assignment Types
        $Chart = New-ExcelChartDefinition -ChartType Pie `
                                    -XRange 'Assignment_Type' `
                                    -YRange 'Assignments' `
                                    -Title "Assignment Types" `
                                    -TitleSize 10 `
                                    -LegendSize 8 `
                                    -Row ($StartRow - 1) `
                                    -Column ($StartColumn + 2) `
                                    -Width 200 `
                                    -Height 200

        $excel = $Summary.assignmentTypes | Select-Object @{Name = 'Assignment Type'; Expression={$_.type}}, `
                                                            @{Name = 'Percentage'; Expression = {$_.percentage}}, `
                                                            @{Name = 'Assignments'; Expression = {$_.count}} | `
                Export-Excel -ExcelPackage $Excel `
                            -WorksheetName 'Summary' `
                            -StartRow $StartRow `
                            -Title 'Assignment Types' `
                            -TableName 'AssignmentTypes' `
                            -TitleBold `
                            -TitleSize 12 `
                            -AutoNameRange `
                            -ExcelChartDefinition $Chart `
                            -PassThru -WarningAction SilentlyContinue
        
        $StartRow += ($Summary.assignmentTypes.Count + 3)

        # Top Roles
        $Chart = New-ExcelChartDefinition -ChartType BarStacked `
                                            -XRange 'Role' `
                                            -YRange 'Assignment_Count' `
                                            -Title 'Top Roles' `
                                            -TitleSize 10 `
                                            -Row ($StartRow ) `
                                            -RowOffSetPixels -10 `
                                            -Column ($StartColumn + 3) `
                                            -Width 800 `
                                            -Height 350 ` `
                                            -NoLegend
                                            
        $excel = $Summary.topRoles | Sort-Object -Property riskLevel | `
                    Select-Object   @{Name = 'Role'; Expression={$_.roleName}}, `
                                    @{Name = 'Assignment Count'; Expression = {$_.assignmentCount}}, `
                                    @{Name = 'Risk Level'; Expression={$_.riskLevel}}, `
                                    @{Name = 'Services'; Expression = {$_.services -join ','}} | `
                    Export-Excel    -ExcelPackage $excel `
                                    -WorksheetName 'Summary' `
                                    -StartRow $StartRow `
                                    -TableName 'topRoles' `
                                    -Title 'Top Roles' `
                                    -TitleBold `
                                    -TitleSize 14 `
                                    -AutoNameRange `
                                    -ExcelChartDefinition $Chart `
                                    -PassThru -WarningAction SilentlyContinue

        $StartRow += ($Summary.topRoles.Count + 3)

        Write-Host "✓ Summary dashboard created" -ForegroundColor Green
        
        # === CREATE SHEETS ===

        # ==== Assignments By Roles ====
        Write-Host "Creating Assignments by Role Sheet..." -ForegroundColor Cyan

        $StartRow = 1
        
        # Group Data By Service
        $Worksheet = $excel.Workbook.Worksheets.Add("by Role")
        
        $resultsByService = $AuditResults | Group-Object -Property Service
        foreach ($Service in $resultsByService) {
            $Range = $Worksheet.Cells.Item($StartRow, $StartColumn).Address
            Set-ExcelRange  -Range $Range `
                            -Worksheet $Worksheet `
                            -FontColor Blue `
                            -FontSize 14 `
                            -Bold `
                            -Value $Service.Name 

            $Range = $Worksheet.Cells.Item($StartRow, $StartColumn + 1).Address
            Set-ExcelRange  -Range $Range`
                            -Worksheet $Worksheet `
                            -FontColor Blue `
                            -FontSize 14 `
                            -Value 'Assignments:' `
                            -HorizontalAlignment:Right

            $Range = $Worksheet.Cells.Item($StartRow, $StartColumn + 2).Address 
            Set-ExcelRange  -Range $Range `
                            -Worksheet $Worksheet `
                            -FontSize 14 `
                            -Value $Service.Count 
    
            $serviceByRoleName = $Service.Group | Group-Object -Property RoleName

            $StartRow += 2

            foreach ($Role in $serviceByRoleName) {
                $Range = $Worksheet.Cells.Item($StartRow, $StartColumn).Address
                Set-ExcelRange  -Range $Range `
                                -Worksheet $Worksheet `
                                -FontColor Blue `
                                -FontSize 12 `
                                -Bold `
                                -Value $Role.Name 

                $Range = $Worksheet.Cells.Item($StartRow,$StartColumn + 1).Address
                Set-ExcelRange  -Range $Range `
                                -Worksheet $Worksheet `
                                -FontColor Blue `
                                -FontSize 12 `
                                -Value 'Assignments:' `
                                -HorizontalAlignment:Right 

                $Range = $Worksheet.Cells.Item($StartRow, $StartColumn + 2).Address
                Set-ExcelRange -Range $Range `
                               -Worksheet $Worksheet `
                                -FontSize 12 `
                                -Value $Role.Count 

                $StartRow += 1
                $random = Get-Random
                $TableName = ($Role.Name -replace " ","_") + $random.ToString()
                $excel = $Role.Group | Select-Object DisplayName, UserPrincipalName, AssignmentType | `
                    Export-Excel    -ExcelPackage $excel `
                                    -WorksheetName $Worksheet.Name `
                                    -TableName $TableName `
                                    -StartRow $StartRow `
                                    -PassThru

                $StartRow += ($Role.Count + 2)
            }
            
        }

        Write-Host "✓ By Role Sheet created" -ForegroundColor Green

        # ==== Assignments By Users ====

        Write-Host "Creating Assignments by User Sheet..." -ForegroundColor Cyan

        $resultsByUser = $AuditResults | Group-Object -Property displayName

        $Worksheet = $excel.Workbook.Worksheets.Add('By User')

        $StartRow = 1

        foreach ($User in $resultsByUser) {
            $Random = Get-Random
            $TableName = ($User.displayName -replace " ","_") + $Random.ToString()
            $Range = $Worksheet.Cells.Item($StartRow, $StartColumn).Address
            Set-ExcelRange -Range $Range `
                            -Worksheet $Worksheet `
                            -FontSize 14 `
                            -FontColor Blue `
                            -Value $User.Name
            
            $Range = $Worksheet.Cells.Item($StartRow, $StartColumn + 1).Address
            Set-ExcelRange -Range $Range `
                            -Worksheet $Worksheet `
                            -FontSize 14 `
                            -FontColor Blue `
                            -Value 'Assignments:' `
                            -HorizontalAlignment:Right
            
            $Range = $Worksheet.Cells.Item($StartRow, $StartColumn + 2).Address
            Set-ExcelRange -Range $Range `
                            -Worksheet $Worksheet `
                            -FontSize 14 `
                            -Value $User.Count

            $StartRow += 2

            $UserResultsByService = $User.Group | Group-Object -Property Service

            foreach ($Service in $UserResultsByService) {
                $Range = $Worksheet.Cells.Item($StartRow, $StartColumn).Address
                Set-ExcelRange -Range $Range `
                                -Worksheet $Worksheet `
                                -FontSize 12 `
                                -FontColor Blue `
                                -Value $Service.Name `

                $Range = $Worksheet.Cells.Item($StartRow, $StartColumn + 1).Address
                Set-ExcelRange -Range $Range `
                                -Worksheet $Worksheet `
                                -FontSize 12 `
                                -FontColor Blue `
                                -Value 'Assignments:' `
                                -HorizontalAlignment:Right
                
                $Range = $Worksheet.Cells.Item($StartRow, $StartColumn + 3).Address
                Set-ExcelRange -Range $Range `
                                -Worksheet $Worksheet `
                                -FontSize 12 `
                                -Value $Service.Assignments 
                
                
                $StartRow += 1
                $TableName = "Table_" + (Get-Random).ToString()
                $excel = $Service.Group | Select-Object DisplayName, RoleName | `
                    Export-Excel -ExcelPackage $excel `
                                    -WorksheetName $Worksheet.Name `
                                    -StartRow $StartRow`
                                    -TableName $TableName `
                                    -PassThru               
                $StartRow += ($Service.count +2) 
            }

        }

        Write-Host "✓ By User sheet created" -ForegroundColor Green

        # ==== Raw Data Sheet ====

        $Worksheet = $excel.Workbook.Worksheets.Add('Audit Data')
        $StartRow = 1

        $excel = $AuditResults | Sort-Object -Property Service,RoleName | `
                        Export-Excel    -ExcelPackage $excel `
                                        -WorksheetName $Worksheet.Name `
                                        -StartRow $StartRow `
                                        -TableName 'AuditData' `
                                        -PassThru

        Close-ExcelPackage -ExcelPackage $excel
    }
    catch {
        Write-Error "Failed to generate Excel report: $($_.Exception.Message)"
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
        throw $_
        # Cleanup on error
        if (Test-Path $OutputPath) {
            try {
                Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Could not clean up partial file: $OutputPath"
            }
        }
        
        return $null
    }
}