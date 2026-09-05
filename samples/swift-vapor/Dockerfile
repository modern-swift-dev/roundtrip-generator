# Generated code. Do not edit.
FROM swift:6.0 AS build

WORKDIR /build
COPY Package.swift ./
RUN swift package resolve
COPY Sources ./Sources
RUN swift build -c release

FROM swift:6.0

WORKDIR /app
COPY --from=build /build/.build/release/Run ./Run

EXPOSE 8080
ENTRYPOINT ["./Run"]
CMD ["serve", "--hostname", "0.0.0.0"]
