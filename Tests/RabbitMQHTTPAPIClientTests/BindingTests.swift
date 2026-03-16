// Copyright (C) 2025-2026 Michael S. Klishin and Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import RabbitMQHTTPAPIClient
import Testing

@Suite struct BindingTests {
  let client = newClient()

  @Test func bindQueueToExchangeAndListAll() async throws {
    try await withTestVhost("bind-q-x") { vh in
      let qName = "swift.test.bind.q"
      let xName = "swift.test.bind.x"

      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))
      try await client.declareExchange(ExchangeParams.fanout(xName, in: vh))
      try await client.bindQueue(qName, to: xName, in: vh, routingKey: "rk1")

      let foundInAll = try await pollUntil {
        let all = try await client.listBindings(in: vh)
        return all.contains { $0.source == xName && $0.destination == qName }
      }
      #expect(foundInAll, "Binding should appear in vhost binding listing")

      let foundInQueue = try await pollUntil {
        let queueBindings = try await client.listQueueBindings(qName, in: vh)
        return queueBindings.contains { $0.source == xName && $0.routingKey == "rk1" }
      }
      #expect(foundInQueue, "Binding should appear in queue binding listing")
    }
  }

  @Test func listQueueBindingsIncludesDefault() async throws {
    try await withTestVhost("default-bind") { vh in
      let name = "swift.test.qbind"
      try await client.declareQueue(QueueParams.classicQueue(name, in: vh))

      let found = try await pollUntil {
        let bindings = try await client.listQueueBindings(name, in: vh)
        return bindings.contains { $0.source == "" }
      }
      #expect(found, "Default binding should appear in queue binding listing")
    }
  }

  @Test func listExchangeBindingsAsSource() async throws {
    try await withTestVhost("x-src-bind") { vh in
      let qName = "swift.test.xsrc.q"
      let xName = "swift.test.xsrc.x"

      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))
      try await client.declareExchange(ExchangeParams.fanout(xName, in: vh))
      try await client.bindQueue(qName, to: xName, in: vh)

      let found = try await pollUntil {
        let bindings = try await client.listExchangeBindingsAsSource(xName, in: vh)
        return bindings.contains { $0.destination == qName }
      }
      #expect(found, "Binding should appear in exchange source listing")
    }
  }

  @Test func deleteQueueBinding() async throws {
    try await withTestVhost("del-q-bind") { vh in
      let qName = "swift.test.delbind.q"
      let xName = "swift.test.delbind.x"

      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))
      try await client.declareExchange(ExchangeParams.fanout(xName, in: vh))
      try await client.bindQueue(qName, to: xName, in: vh, routingKey: "del-rk")

      let found = try await pollUntil {
        let bindings = try await client.listQueueBindings(qName, in: vh)
        return bindings.contains { $0.source == xName }
      }
      #expect(found, "Binding should appear in queue binding listing")

      let bindings = try await client.listQueueBindings(qName, in: vh)
      if let pk = bindings.first(where: { $0.source == xName })?.propertiesKey {
        try await client.deleteQueueBinding(
          qName, from: xName, in: vh, propertiesKey: pk)

        let after = try await client.listQueueBindings(qName, in: vh)
        #expect(!after.contains { $0.source == xName })
      }
    }
  }

  @Test func deleteExchangeBinding() async throws {
    try await withTestVhost("del-x-bind") { vh in
      let srcX = "swift.test.xdel.src"
      let dstX = "swift.test.xdel.dst"

      try await client.declareExchange(ExchangeParams.fanout(srcX, in: vh))
      try await client.declareExchange(ExchangeParams.fanout(dstX, in: vh))
      try await client.bindExchange(dstX, to: srcX, in: vh, routingKey: "x-rk")

      let found = try await pollUntil {
        let bindings = try await client.listExchangeBindingsAsDestination(dstX, in: vh)
        return bindings.contains { $0.source == srcX }
      }
      #expect(found, "Binding should appear in exchange destination listing")

      let bindings = try await client.listExchangeBindingsAsDestination(dstX, in: vh)
      if let pk = bindings.first(where: { $0.source == srcX })?.propertiesKey {
        try await client.deleteExchangeBinding(
          dstX, from: srcX, in: vh, propertiesKey: pk)

        let after = try await client.listExchangeBindingsAsDestination(dstX, in: vh)
        #expect(!after.contains { $0.source == srcX })
      }
    }
  }

  @Test func listQueueBindingsBetween() async throws {
    try await withTestVhost("q-x-between") { vh in
      let qName = "swift.test.between.q"
      let xName = "swift.test.between.x"

      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))
      try await client.declareExchange(ExchangeParams.topic(xName, in: vh))
      try await client.bindQueue(qName, to: xName, in: vh, routingKey: "test.#")

      let found = try await pollUntil {
        let bindings = try await client.listQueueBindingsBetween(qName, and: xName, in: vh)
        return bindings.contains { $0.routingKey == "test.#" }
      }
      #expect(found, "Binding should appear between queue and exchange")
    }
  }

  @Test func listExchangeBindingsBetween() async throws {
    try await withTestVhost("x-x-between") { vh in
      let srcX = "swift.test.xbetween.src"
      let dstX = "swift.test.xbetween.dst"

      try await client.declareExchange(ExchangeParams.topic(srcX, in: vh))
      try await client.declareExchange(ExchangeParams.fanout(dstX, in: vh))
      try await client.bindExchange(dstX, to: srcX, in: vh, routingKey: "events.#")

      let found = try await pollUntil {
        let bindings = try await client.listExchangeBindingsBetween(
          source: srcX, destination: dstX, in: vh)
        return bindings.contains { $0.routingKey == "events.#" }
      }
      #expect(found, "Binding should appear between exchanges")
    }
  }

  @Test func bindQueueWithArguments() async throws {
    try await withTestVhost("bind-args") { vh in
      let qName = "swift.test.bindargs.q"
      let xName = "swift.test.bindargs.x"

      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))
      try await client.declareExchange(ExchangeParams.headers(xName, in: vh))
      try await client.bindQueue(
        qName, to: xName, in: vh,
        arguments: ["x-match": .string("all"), "category": .string("test")])

      let found = try await pollUntil {
        let bindings = try await client.listQueueBindingsBetween(qName, and: xName, in: vh)
        return !bindings.isEmpty
      }
      #expect(found, "Binding with arguments should appear")
    }
  }

  @Test func listExchangeBindingsAsDestination() async throws {
    try await withTestVhost("x-dst-bind") { vh in
      let srcX = "swift.test.xdst.src"
      let dstX = "swift.test.xdst.dst"

      try await client.declareExchange(ExchangeParams.fanout(srcX, in: vh))
      try await client.declareExchange(ExchangeParams.fanout(dstX, in: vh))
      try await client.bindExchange(dstX, to: srcX, in: vh)

      let found = try await pollUntil {
        let bindings = try await client.listExchangeBindingsAsDestination(dstX, in: vh)
        return bindings.contains { $0.source == srcX }
      }
      #expect(found, "Binding should appear in exchange destination listing")
    }
  }
}
