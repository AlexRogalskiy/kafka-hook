FROM yolean/builder-quarkus:dc1392b4cdb17073343b113213cba34efef9aabf@sha256:56822ca3bc46c41308966e59a045783d557d352db8a31ec60c4ff3229669de59 \
  as dev

COPY --chown=nonroot:nogroup pom.xml .
COPY --chown=nonroot:nogroup lib/pom.xml lib/
COPY --chown=nonroot:nogroup rest/pom.xml rest/

RUN mkdir -p rest/target/
RUN cd lib && y-build-quarkus-cache

COPY . .

ENTRYPOINT [ "mvn", "quarkus:dev" ]
CMD [ "-Dquarkus.http.host=0.0.0.0", "-Dquarkus.http.port=8080" ]

# The jar and the lib folder is required for the jvm target even when the native target is the end result
# Also we want to run the tests here, regardless of build target
RUN mvn --batch-mode package
# Produce the input to native builds, it's cheap until we actually run native-image
RUN mvn --batch-mode package -Pnative -Dquarkus.native.additional-build-args=--dry-run -Dmaven.test.skip=true \
  || echo "= BUILD ERROR IS OK: Producing native-image source jar."

# Defaults to native-image build because that's the default target
ARG build="native-image"
# JVM builds can use a dummy mvn target: --target=jvm --build-arg=build="validate"
# Native builds can be in-maven (+2GB mem): build="package -Pnative -Dmaven.test.skip=true"

RUN test "$build" = "native-image" || mvn --batch-mode $build

RUN test "$build" != "native-image" || ( \
  cd rest/target/*-native-image-source-jar && \
  native-image $(curl -sL https://github.com/solsson/quarkus-graalvm-builds/raw/593699ab9795414fd8b992922dd4d9611c3184bf/rest-json-quickstart.txt | sed 's/__APP__/kafka-hook-rest-1.0-SNAPSHOT/g') && \
  mv *-runner ../ \
)

FROM yolean/java:dc1392b4cdb17073343b113213cba34efef9aabf@sha256:f19fc496ebee75a4397e1b4bb0e4acc0868c73d64f420e9b43bd14e277083e0d \
  as jvm

WORKDIR /app
COPY --from=dev /workspace/rest/target/lib ./lib
COPY --from=dev /workspace/rest/target/*-runner.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", \
  "-Dquarkus.http.host=0.0.0.0", \
  "-Dquarkus.http.port=8080", \
  "-Djava.util.logging.manager=org.jboss.logmanager.LogManager", \
  "-cp", "./lib/*", \
  "-jar", "./app.jar" ]

FROM yolean/runtime-quarkus:dc1392b4cdb17073343b113213cba34efef9aabf@sha256:5036788a4e94e72a96858a13f04f3a3541ad1fb4b956c38119f05a76bab578cf

COPY --from=dev /workspace/rest/target/*-runner /usr/local/bin/quarkus
