## Elastic-Monitoring Kubernetes Cron Job

---

This microservice, in a nutshell, hits Elastic-Cluster endpoints (provided for monitoring the cluster's health), and analysis the results with provided rules to see if values are as expected. Oh, and its written in Ruby.

Basically, its just comparing the json response with ideal/preferred values. Read the [**`why`**][1] section for more details.

---

### How to use this?

Its a Kubernetes cron job. So,

* Edit the ElasticSearch URI to use for connection in [**lib/es_monitor.rb**][2]
* Build the image using Dockerfile
* Push it to your preferred Docker repo
* Update the image-name in **k8s_cron_job.yml** (adjust other `spec` as required)
* Deploy to Kubernetes

---

### Why?

The primary feature of this is the **template-based JSON validation**. Or basically, comparing values between JSON structures *without using any conditional statements*. This is something I wanted to develop, less for the use-case and more as a small challenge.

#### How is it achieved?

You specify the *rules* for the JSON you are trying to compare with. The comparison is done recursively and if the rule(s) doesn't match, it outputs what was expected and what was received, to put it simply.

#### How to change rules?

The main idea behind this sort of JSON comparison feature is to allow comparing while keeping the JSON structure consistent (easy to read, compared to using conditional statements). Further, conditional statements often also force checking existence of parent key to verify the value of nested key. This templating feature fixes that.

The example usage, and rules can be viewed/changed here [**lib/es_health_rules**][3].

#### How to change the way error messages are handled

The *transport* method for error messages is defined in [**lib/monitor_engine/alert**][4]. Currently, it just prints to stdout.

---

## Details on Template-Compare engine

More details about this template-comparison feature (including READMe on how to use it, and additional features offered) can be found here [**lib/monitor_engine**][5].

---

#### Why use Ruby?

Considering all the cons/possible-downsides the language might bring, I can probably just pretty much say this: *Because I can, and I wanted to*.

---

### Other FAQs

#### Can I contribute, or use this code in my own project(s)?

Yeah, do whatever with it. Just give credits where due.

  [1]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron#why
  [2]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/blob/master/lib/es_monitor.rb#L12
  [3]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/es_health_rules
  [4]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/blob/master/lib/monitor_engine/alert.rb
  [5]: https://github.com/Jaskaranbir/ElasticSearch_Monitor_K8s_Cron/tree/master/lib/monitor_engine
