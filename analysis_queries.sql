/* ============================================================
   Project: Customer Operations KPI Analysis
   Table:   customer_ops_data
   Columns: TicketID, Date, Weekday, Region, Channel, Category,
            Priority, AssignedAgent, HandleTimeMinutes,
            ResolutionHours, SLA_Target_Hours, SLA_Breached,
            Escalated, FirstContactResolution, CSAT_Score
   ============================================================ */

-- 1. Overall KPI summary
SELECT
    COUNT(*)                                                        AS total_tickets,
    ROUND(100.0 * SUM(CASE WHEN FirstContactResolution='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fcr_pct,
    ROUND(100.0 * SUM(CASE WHEN SLA_Breached='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1)            AS sla_breach_pct,
    ROUND(100.0 * SUM(CASE WHEN Escalated='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1)               AS escalation_pct,
    ROUND(AVG(CSAT_Score), 2)                                       AS avg_csat,
    ROUND(AVG(HandleTimeMinutes), 1)                                AS avg_handle_time_min
FROM customer_ops_data;

-- 2. Escalation rate by day of week (surfaces the Monday spike)
SELECT
    Weekday,
    COUNT(*)                                                         AS tickets,
    ROUND(100.0 * SUM(CASE WHEN Escalated='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS escalation_pct
FROM customer_ops_data
GROUP BY Weekday
ORDER BY escalation_pct DESC;

-- 3. SLA breach rate by category
SELECT
    Category,
    COUNT(*)                                                         AS tickets,
    ROUND(100.0 * SUM(CASE WHEN SLA_Breached='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS sla_breach_pct
FROM customer_ops_data
GROUP BY Category
ORDER BY sla_breach_pct DESC;

-- 4. First Contact Resolution rate by category
SELECT
    Category,
    COUNT(*)                                                         AS tickets,
    ROUND(100.0 * SUM(CASE WHEN FirstContactResolution='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fcr_pct
FROM customer_ops_data
GROUP BY Category
ORDER BY fcr_pct ASC;

-- 5. Average handle time by channel
SELECT
    Channel,
    COUNT(*)                    AS tickets,
    ROUND(AVG(HandleTimeMinutes), 1) AS avg_handle_time_min
FROM customer_ops_data
GROUP BY Channel
ORDER BY avg_handle_time_min DESC;

-- 6. Average CSAT by region
SELECT
    Region,
    COUNT(*)              AS tickets,
    ROUND(AVG(CSAT_Score), 2) AS avg_csat
FROM customer_ops_data
GROUP BY Region
ORDER BY avg_csat ASC;

-- 7. Agent performance leaderboard (FCR%, min. 20 tickets handled)
SELECT
    AssignedAgent,
    COUNT(*)                                                         AS tickets_handled,
    ROUND(100.0 * SUM(CASE WHEN FirstContactResolution='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fcr_pct,
    ROUND(AVG(HandleTimeMinutes), 1)                                 AS avg_handle_time_min
FROM customer_ops_data
GROUP BY AssignedAgent
HAVING COUNT(*) >= 20
ORDER BY fcr_pct ASC
LIMIT 5;

-- 8. Monthly ticket volume trend (for a time-series chart)
SELECT
    STRFTIME('%Y-%m', Date) AS month,
    COUNT(*)                AS tickets,
    ROUND(100.0 * SUM(CASE WHEN SLA_Breached='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS sla_breach_pct
FROM customer_ops_data
GROUP BY month
ORDER BY month;

-- 9. Priority mix vs. SLA breach (does urgent triage actually help?)
SELECT
    Priority,
    COUNT(*)                                                         AS tickets,
    ROUND(100.0 * SUM(CASE WHEN SLA_Breached='Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS sla_breach_pct,
    ROUND(AVG(ResolutionHours), 1)                                   AS avg_resolution_hours
FROM customer_ops_data
GROUP BY Priority
ORDER BY CASE Priority WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END;
