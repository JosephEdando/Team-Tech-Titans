
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TitanSentaraModule = buildModule("TitanSentaraModule", (m) => {

  const TitanSentara = m.contract("TitanSentara");

  return { TitanSentara };
});

export default TitanSentaraModule;