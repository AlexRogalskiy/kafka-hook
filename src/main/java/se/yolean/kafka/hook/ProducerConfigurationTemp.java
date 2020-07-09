package se.yolean.kafka.hook;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.clients.producer.ProducerConfig;

/**
 * Can be moved into ProducerConfiguration with Quarkus 1.6
 * - https://github.com/quarkusio/quarkus/pull/9771
 */
public interface ProducerConfigurationTemp {

  /*@ConfigIgnore*/ static Map<String,Object> toProps(ProducerConfiguration c) {
    Map<String, Object> props = new HashMap<>(10);
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, c.getBootstrapServer());
    props.put(ProducerConfig.ACKS_CONFIG, c.getAcks());
    props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, c.getEnableIdempotence());
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, c.getKeySerializer());
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, c.getVallueSerializer());
    if (c.getRequestTimeoutMs().isPresent()) {
      props.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, c.getRequestTimeoutMs().orElseThrow());
    }
    if (c.getMaxBlockMs().isPresent()) {
      props.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, c.getMaxBlockMs().orElseThrow());
    }
    return props;
  }

}
