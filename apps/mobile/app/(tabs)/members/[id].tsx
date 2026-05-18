import { View, Text, ScrollView, StyleSheet, ActivityIndicator } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { membersService } from '../../../services/members';

export default function MemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [member, setMember] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadMember();
  }, [id]);

  const loadMember = async () => {
    try {
      const res = await membersService.getById(id);
      setMember(res.data.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <ActivityIndicator style={{ marginTop: 40 }} />;
  if (!member) return <Text style={{ textAlign: 'center', marginTop: 40 }}>Membro não encontrado</Text>;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{member.name?.charAt(0)?.toUpperCase()}</Text>
        </View>
        <Text style={styles.name}>{member.name}</Text>
        <Text style={styles.role}>{member.role} • {member.status}</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Contato</Text>
        <Text style={styles.field}>Email: {member.email || '-'}</Text>
        <Text style={styles.field}>Telefone: {member.phone || '-'}</Text>
      </View>

      {member.address && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Endereço</Text>
          <Text style={styles.field}>{member.address.street}, {member.address.number}</Text>
          <Text style={styles.field}>{member.address.neighborhood} - {member.address.city}/{member.address.state}</Text>
        </View>
      )}

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Informações</Text>
        <Text style={styles.field}>Data de Nascimento: {member.dateOfBirth ? new Date(member.dateOfBirth).toLocaleDateString('pt-BR') : '-'}</Text>
        <Text style={styles.field}>Estado Civil: {member.maritalStatus || '-'}</Text>
        <Text style={styles.field}>Batizado: {member.isBaptized ? 'Sim' : 'Não'}</Text>
        {member.ministry && <Text style={styles.field}>Ministério: {member.ministry.name}</Text>}
      </View>

      {member.familyMembers?.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Família</Text>
          {member.familyMembers.map((fm: any) => (
            <Text key={fm.id} style={styles.field}>{fm.name} ({fm.kinship})</Text>
          ))}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  header: { alignItems: 'center', padding: 24, backgroundColor: '#fff' },
  avatar: { width: 72, height: 72, borderRadius: 36, backgroundColor: '#1a73e8', justifyContent: 'center', alignItems: 'center', marginBottom: 12 },
  avatarText: { color: '#fff', fontSize: 28, fontWeight: 'bold' },
  name: { fontSize: 22, fontWeight: 'bold' },
  role: { fontSize: 14, color: '#666', marginTop: 4 },
  section: { backgroundColor: '#fff', margin: 12, padding: 16, borderRadius: 8 },
  sectionTitle: { fontSize: 16, fontWeight: '600', marginBottom: 8, color: '#1a73e8' },
  field: { fontSize: 14, color: '#333', marginVertical: 2 },
});
