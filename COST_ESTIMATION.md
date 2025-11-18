# Azure Front Door Cost Estimation Guide

This guide helps you estimate the cost of using Azure Front Door for your workload.

## Quick Reference

| Usage Pattern | Recommended SKU | Estimated Monthly Cost |
|--------------|-----------------|----------------------|
| Small blog/website | Standard | $40-100 |
| Medium web app | Standard | $100-300 |
| Large enterprise app | Standard | $300-1,000 |
| Private network app | Premium | $350-500 (base) |
| High-traffic SaaS | Premium | $1,000-5,000+ |

## Billing Components

### 1. Base Profile Fee (Hourly)
- **Standard**: $0.048/hour = ~$35/month
- **Premium**: $0.45/hour = ~$330/month

### 2. Data Transfer Out (Per GB)
Pricing tiers:
```
0-10 TB:      $0.085/GB
10-50 TB:     $0.080/GB
50-150 TB:    $0.060/GB
150-500 TB:   $0.040/GB
500+ TB:      $0.030/GB
```

### 3. HTTP/HTTPS Requests
- $0.0075 per 10,000 requests
- $0.75 per 1 million requests

### 4. WAF Requests
- $0.50 per 1 million requests (when WAF processes them)

### 5. Custom WAF Rules
- First 5 rules: Free
- Additional rules: $1/rule/month

### 6. Private Link (Premium Only)
- $0.01/hour per private endpoint connection
- ~$7.30/month per endpoint

## Cost Calculation Examples

### Example 1: Small Blog (Standard SKU)

**Traffic Profile:**
- 100,000 page views/month
- 500,000 HTTP requests/month (images, CSS, JS)
- 50 GB data transfer/month
- Basic WAF with default rules

**Cost Breakdown:**
```
Base fee:           $35.00
Data transfer:      $4.25  (50 GB × $0.085)
HTTP requests:      $0.38  (500K requests)
WAF requests:       $0.25  (500K requests)
Custom rules:       $0.00  (using defaults only)
-----------------------------------
Total:             ~$40/month
```

### Example 2: E-commerce Site (Standard SKU)

**Traffic Profile:**
- 1 million page views/month
- 10 million HTTP requests/month
- 500 GB data transfer/month (with compression enabled)
- 3 custom WAF rules
- 2 custom domains

**Cost Breakdown:**
```
Base fee:           $35.00
Data transfer:      $42.50  (500 GB × $0.085)
HTTP requests:      $7.50   (10M requests)
WAF requests:       $5.00   (10M requests)
Custom rules:       $0.00   (first 5 free)
Custom domains:     $0.00   (included)
-----------------------------------
Total:             ~$90/month
```

### Example 3: SaaS Application (Premium with Private Link)

**Traffic Profile:**
- 10 million API calls/month
- 50 million HTTP requests/month
- 5 TB data transfer/month
- 10 custom WAF rules
- 3 private endpoints (App Service, SQL, Storage)

**Cost Breakdown:**
```
Base fee:           $330.00
Private endpoints:  $21.90   (3 × $7.30)
Data transfer:      $425.00  (5 TB × $0.085)
HTTP requests:      $37.50   (50M requests)
WAF requests:       $25.00   (50M requests)
Custom rules:       $5.00    (5 extra rules)
-----------------------------------
Total:             ~$844/month
```

### Example 4: High-Traffic Media Site (Standard SKU)

**Traffic Profile:**
- 50 million page views/month
- 500 million HTTP requests/month
- 50 TB data transfer/month (images, videos)
- Caching enabled (80% cache hit rate)

**Cost Breakdown:**
```
Base fee:           $35.00
Data transfer:      $3,475.00  (10TB @ $0.085 + 40TB @ $0.080)
HTTP requests:      $375.00    (500M requests)
WAF requests:       $250.00    (500M requests)
Custom rules:       $0.00      (defaults only)
-----------------------------------
Total:             ~$4,135/month
```

## Cost Optimization Strategies

### 1. Enable Caching (Save 60-80% on origin costs)
```hcl
cache = {
  query_string_caching_behavior = "IgnoreQueryString"
  compression_enabled           = true
  content_types_to_compress     = [
    "text/html",
    "text/css", 
    "application/javascript",
    "application/json",
    "image/svg+xml"
  ]
}
```

### 2. Use Compression (Reduce data transfer by 60-80%)
Enable compression for text-based content types to significantly reduce bandwidth costs.

### 3. Optimize Health Probes
```hcl
health_probe = {
  protocol            = "Https"
  interval_in_seconds = 120  # Increase from 30s to reduce requests
  request_type        = "HEAD"  # Lighter than GET
  path                = "/health"
}
```

### 4. Right-Size Your SKU
- Use **Standard** unless you need Private Link
- Premium costs 9x more ($330 vs $35 base fee)
- Only upgrade for private connectivity requirements

### 5. Consolidate WAF Rules
- Keep custom rules under 5 (first 5 are free)
- Use managed rule overrides instead of custom rules where possible

### 6. Use Query String Caching Wisely
```hcl
cache = {
  query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
  query_strings                 = ["utm_source", "utm_campaign"]
  # Ignore tracking params to improve cache hit ratio
}
```

### 7. Monitor and Alert
Set up cost alerts to catch unexpected spikes:
- Alert at 80% of budget
- Alert at 100% of budget
- Review costs weekly

## ROI Considerations

### Benefits vs. Traditional CDN
Azure Front Door provides:
- ✅ **Global distribution** (Microsoft backbone network)
- ✅ **Integrated WAF** (would cost $10-50/month separately)
- ✅ **Load balancing** (would cost $20-30/month separately)
- ✅ **SSL management** (free certificates)
- ✅ **DDoS protection** (included)

### Cost Comparison: Front Door vs Alternatives

| Solution | Monthly Cost | Features |
|----------|-------------|----------|
| Front Door Standard | $35 + usage | Full-featured, WAF included |
| Application Gateway + CDN | $150 + usage | Separate services, more complex |
| Cloudflare Pro | $20 + usage | Limited control, external vendor |
| NGINX + VM | $50-200 | Self-managed, higher ops cost |

## Cost Estimation Tool

Use this formula to estimate your costs:

```
Monthly Cost = Base Fee + Data Transfer + Requests + WAF + Extra Rules + Private Links

Where:
  Base Fee        = $35 (Standard) or $330 (Premium)
  Data Transfer   = GB_out × $0.085 (use calculator for volume discounts)
  Requests        = (Requests / 1,000,000) × $0.75
  WAF             = (WAF_Requests / 1,000,000) × $0.50
  Extra Rules     = max(0, Custom_Rules - 5) × $1
  Private Links   = Endpoints × $7.30 (Premium only)
```

## Questions to Ask Before Deployment

1. **What's your expected monthly traffic?**
   - Page views/API calls
   - Data transfer volume
   
2. **Do you need Private Link?**
   - If no → Use Standard SKU
   - If yes → Budget for Premium SKU

3. **How many custom WAF rules?**
   - 5 or fewer → No extra cost
   - More than 5 → $1/month per extra rule

4. **What's your caching strategy?**
   - Good caching can save 60-80% on bandwidth
   
5. **What's your region distribution?**
   - Global audience → More value from Front Door
   - Single region → Consider alternatives

## Additional Resources

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Front Door Pricing Page](https://azure.microsoft.com/pricing/details/frontdoor/)
- [Azure Cost Management](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview)
- [Azure Well-Architected Framework - Cost Optimization](https://docs.microsoft.com/azure/architecture/framework/cost/)

---

**Last Updated**: 2024
**Note**: Prices are subject to change. Always verify current pricing with Azure.
