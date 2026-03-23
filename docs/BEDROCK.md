# Using AWS Bedrock Instead of OpenAI

You can run the Smart GTM Agent with **AWS Bedrock** (e.g. Claude) instead of OpenAI. Bedrock uses your ECS task IAM role—no API key is required.

## Will it work on AWS Free Tier?

- **Standard AWS Free Tier** does **not** include Bedrock. Bedrock is **pay-per-use** (per input/output token).
- **New AWS accounts** (e.g. created after mid-2025) may receive **promotional credits** that can be used for Bedrock; check your account’s credits and [Bedrock pricing](https://aws.amazon.com/bedrock/pricing/).
- **Claude Haiku** is one of the lower-cost models; usage is still billed but typically cheaper than OpenAI for similar use.

So: **yes, the app will work** with Bedrock. **Cost:** you pay for Bedrock usage unless you have credits. To avoid any cost, use **MOCK_MODE** (mock plans, no LLM calls).

## Enable Bedrock in the app

1. **Enable the model in AWS**  
   In the [Bedrock console](https://console.aws.amazon.com/bedrock/) → **Model access** (or **Get started**), request access to **Anthropic Claude** (e.g. Claude 3 Haiku). Wait until access is granted.

2. **Switch Terraform to Bedrock**  
   In `terraform/terraform.tfvars`:

   ```hcl
   backend_llm_provider = "bedrock"
   # Optional: default is Claude 3 Haiku (cheaper)
   # backend_bedrock_model_id = "anthropic.claude-3-haiku-20240307-v1:0"
   ```

3. **Apply and redeploy**

   ```bash
   cd terraform
   terraform apply -auto-approve -lock=false
   aws ecs update-service --cluster smart-gtm-agent-cluster --service smart-gtm-agent-backend --force-new-deployment --region us-east-1
   ```

4. Wait 1–2 minutes, then use the app. **Generate GTM Plan** will call Bedrock (Claude) instead of OpenAI.

## Switching back to OpenAI

Set in `terraform.tfvars`:

```hcl
backend_llm_provider = "openai"
```

Then run `terraform apply` and force a new ECS deployment. Ensure the OpenAI API key is set in Secrets Manager.
